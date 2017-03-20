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

require "kitchen"
require "kitchen/config/plan"

::RSpec.shared_examples ::Kitchen::Config::Plan do
  describe "finalize_config!" do
    let :configuration do default_config end

    let :described_instance do described_class.new configuration end

    shared_examples "the configuration is invalid" do
      subject do proc do instance end end

      it "raises a user error" do
        is_expected.to raise_error ::Kitchen::UserError, error_message
      end
    end

    shared_context "valid :plan" do
      before do instance end

      subject do described_instance[:plan] end
    end

    shared_examples "the configuration is valid" do
      include_context "valid :plan"

      it "permits the configuration" do is_expected.to match validated_plan end
    end

    context "when the configuration omits :plan" do
      include_context "valid :plan"

      it "alters the configuration to associate :plan with terraform.tfplan " \
           "under the Test Kitchen suite directory" do
        is_expected.to eq "/kitchen/root/.kitchen/kitchen-terraform/" \
                            "suite-platform/terraform.tfplan"
      end
    end

    context "when the configuration associates :plan with a nonstring" do
      before do configuration.store :plan, 123 end

      it_behaves_like "the configuration is invalid" do
        let :error_message do /plan.*must be a string/ end
      end
    end

    context "when the configuration associates :plan with a string" do
      let :string do ::String.new end

      before do configuration.store :plan, string end

      context "when the string is empty" do
        it_behaves_like "the configuration is invalid" do
          let :error_message do /plan.*must be filled/ end
        end
      end

      context "when the string is nonempty" do
        before do string.replace "/plan" end

        it_behaves_like "the configuration is valid" do
          let :validated_plan do "/plan" end
        end
      end
    end
  end
end
