FactoryBot.modify do
  factory :adjustment do
    transient do
      external_source_type { nil }
      external_name { nil }
      trade_agreement_number { nil }
    end

    after(:create) do |adjustment, evaluator|
      {
        external_source_type: :preferred_external_source_type,
        external_name: :preferred_external_name,
        trade_agreement_number: :preferred_trade_agreement_number
      }.each do |attr, pref_writer|
        value = evaluator.public_send(attr)
        next if value.nil?

        adjustment.public_send("#{pref_writer}=", value)
      end

      adjustment.save!
    end
  end
end