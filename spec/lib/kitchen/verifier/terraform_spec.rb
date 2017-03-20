# frozen_string_literal: true

# Copyright 2016-2017 New Context Services, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'inspec'
require 'kitchen/verifier/terraform'
require 'support/kitchen/config/groups_examples'
require 'support/kitchen/instance_context'
require 'support/terraform/configurable_context'
require 'support/terraform/configurable_examples'

::RSpec.describe ::Kitchen::Verifier::Terraform do
  it_behaves_like ::Terraform::Configurable do
    include_context 'instance'

    let(:described_instance) { verifier }
  end

  it_behaves_like ::Kitchen::Config::Groups do
    include_context ::Kitchen::Instance do
      let(:verifier) { described_instance }
    end
  end

  describe '#call(state)' do
    include_context 'instance'

    include_context 'silent_client'

    let(:described_instance) { verifier }

    let :resolved_group do
      unresolved_group
        .merge attributes: { attribute_name: 'attribute output value' },
               hostname: 'localhost'
    end

    let(:runner) { instance_double ::Inspec::Runner }

    let(:runner_class) { class_double(::Inspec::Runner).as_stubbed_const }

    let :unresolved_group do
      ::Terraform::Group
        .new attributes: { attribute_name: 'attribute output name' },
             controls: ['control'], name: 'group', port: 1234,
             username: 'username'
    end

    before do
      default_config
        .merge! groups: [unresolved_group], test_base_path: 'test/base/path'

      allow(unresolved_group).to receive(:resolve).with(client: silent_client)
        .and_yield resolved_group

      allow(runner_class).to receive(:new).with(
        hash_including(
          attributes: {
            'attribute_name' => 'attribute output value',
            'terraform_state' => '/kitchen/root/.kitchen/kitchen-terraform/' \
                                   'suite-platform/terraform.tfstate'
          },
          'backend' => 'local', controls: ['control'],
          'host' => 'localhost', 'port' => 1234, 'user' => 'username'
        )
      ).and_return runner

      allow(runner).to receive(:run).with(no_args).and_return exit_code
    end

    subject { proc { described_instance.call({}) } }

    context 'when the Inspec Runner does return 0' do
      let(:exit_code) { 0 }

      it('does not raise an error') { is_expected.to_not raise_error }
    end

    context 'when the Inspec Runner does not return 0' do
      let(:exit_code) { 1 }

      it 'raises an ActionFailed error' do
        is_expected.to raise_error ::Kitchen::ActionFailed
      end
    end
  end
end
