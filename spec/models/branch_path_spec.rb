require 'rails_helper'

RSpec.describe BranchPath, type: :model do
   subject { build(:branch_path) }

   it { is_expected.to have_db_column(:branch_id) }
   it { is_expected.to have_db_column(:source_path_id) }
   it { is_expected.to have_db_column(:arch) }
   it { is_expected.to have_db_column(:path) }

   it { is_expected.to have_db_index(:source_path_id) }
   it { is_expected.to have_db_index(:branch_id) }
   it { is_expected.to have_db_index(:arch) }
   it { is_expected.to have_db_index(:path) }
   it { is_expected.to have_db_index(%i(arch branch_id source_path_id)).unique(true) }
   it { is_expected.to have_db_index(%i(arch path)).unique(true) }

   it { is_expected.to belong_to(:branch) }
   xit { is_expected.to belong_to(:source_path).with_foreign_key(:source_path_id).class_name("BranchPath").optional }

   it { is_expected.to have_many(:rpms) }
   it { is_expected.to have_many(:packages).through(:rpms) }
   it { is_expected.to have_many(:builders).through(:packages) }

   it { is_expected.to validate_presence_of(:branch) }
   it { is_expected.to validate_presence_of(:arch) }
   it { is_expected.to validate_presence_of(:path) }

   it { is_expected.to validate_inclusion_of(:arch).in_array(%w(i586 x86_64 noarch aarch64 mipsel armh src)) }
end
