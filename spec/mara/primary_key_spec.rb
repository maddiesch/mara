require 'spec_helper'

RSpec.describe  Mara::PrimaryKey do
  describe '.generate' do
    let(:person) { Person.build(partition_key: 'PartitionKeyValue', sort_key: 'SortKeyValue') }

    context 'given a valid model' do
      it { expect( Mara::PrimaryKey.generate(person)).to eq 'WyJwZXJzb24iLCJQYXJ0aXRpb25LZXlWYWx1ZSIsIlNvcnRLZXlWYWx1ZSJd' }
    end

    context 'given a valid primary key' do
      it { expect( Mara::PrimaryKey.generate(person.model_primary_key)).to eq 'WyJwZXJzb24iLCJQYXJ0aXRpb25LZXlWYWx1ZSIsIlNvcnRLZXlWYWx1ZSJd' }
    end

    context 'given a nil value' do
      it { expect {  Mara::PrimaryKey.generate(nil) }.to raise_error(ArgumentError) }
    end
  end

  describe '.parse' do
    let(:payload) { 'WyJwZXJzb24iLCJQYXJ0aXRpb25LZXlWYWx1ZSIsIlNvcnRLZXlWYWx1ZSJd' }

    it { expect( Mara::PrimaryKey.parse(payload)).to_not be_nil }

    it { expect( Mara::PrimaryKey.parse(payload).class_name).to eq 'Person' }

    it { expect( Mara::PrimaryKey.parse(payload).partition_key).to eq 'PartitionKeyValue' }

    it { expect( Mara::PrimaryKey.parse(payload).sort_key).to eq 'SortKeyValue' }
  end
end
