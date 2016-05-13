FactoryGirl.define do
  factory :attributed_to_user_prov_relation do
    association :creator, factory: :user
    is_deleted false
    association :relatable_from, factory: :file_version
    relationship_type { 'was-attributed-to' }
    association :relatable_to, factory: :user
  end
end
