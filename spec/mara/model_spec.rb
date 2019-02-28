require 'spec_helper'

RSpec.describe  Mara::Model do
  describe '#to_dynamo' do
    context 'given a valid model' do
      let(:person) { Person.build(first_name: 'Maddie', last_name: 'Schipper') }

      it { expect { person.to_dynamo }.to_not raise_error }

      it { expect(person.to_dynamo.dig('FirstName', :s)).to eq 'Maddie' }

      it { expect(person.to_dynamo.dig('LastName', :s)).to eq 'Schipper' }
    end
  end

  describe '#model_identifier' do
    it 'has the expected identifier' do
      person = Person.build(partition_key: 'PartitionKeyValue', sort_key: 'SortKeyValue')
      expect(person.model_identifier).to eq 'WyJwZXJzb24iLCJQYXJ0aXRpb25LZXlWYWx1ZSIsIlNvcnRLZXlWYWx1ZSJd'
    end
  end

  describe '#[]=' do
    it 'calls throug to attributes' do
      person = Person.build
      expect(person.attributes).to receive(:set).with(:foo, 'bar')
      person[:foo] = 'bar'
    end
  end

  describe '#[]' do
    it 'calls throug to attributes' do
      person = Person.build
      expect(person.attributes).to receive(:get).with(:foo)
      person[:foo]
    end
  end

  describe 'LSI' do
    describe '#local_secondary_index' do
      it 'raises an error if the index is not defined' do
        expect { Person.local_secondary_index(:foo_bar) }.to raise_error( Mara::Model::IndexError) do |error|
          expect(error.message).to eq "Can't find a LSI with the name `foo_bar`"
        end
      end

      it 'returns the LSI' do
        index = Person.local_secondary_index('local_secondary_index_1')
        expect(index).to be_a( Mara::Model::LocalSecondaryIndex)
      end
    end
  end

  describe 'GSI' do
    describe '#global_secondary_index' do
      it 'raises an error if the index is not defined' do
        expect { Person.global_secondary_index(:foo_bar) }.to raise_error( Mara::Model::IndexError) do |error|
          expect(error.message).to eq "Can't find a GSI with the name `foo_bar`"
        end
      end

      it 'returns the GSI' do
        index = Person.global_secondary_index('global_secondary_index_1')
        expect(index).to be_a( Mara::Model::GlobalSecondaryIndex)
      end
    end
  end

  describe '#save!' do
    context 'given a valid record' do
      let(:person) do
        Person.build(
          partition_key: SecureRandom.uuid,
          sort_key: Time.now.utc.to_f.to_s,
          first_name: 'Maddie',
          last_name: 'Schipper'
        )
      end

      it { expect { person.save! }.to_not raise_error }
    end
  end

  describe '#save' do
    context 'given a valid record' do
      let(:person) do
        Person.build(
          partition_key: SecureRandom.uuid,
          sort_key: Time.now.utc.to_f.to_s,
          first_name: 'Maddie',
          last_name: 'Schipper'
        )
      end

      it { expect(person.save).to eq true }
    end

    context 'given a valid request in a batch' do
      let(:person) do
        Person.build(
          partition_key: SecureRandom.uuid,
          sort_key: Time.now.utc.to_f.to_s,
          first_name: 'Maddie',
          last_name: 'Schipper'
        )
      end

      it 'saved after the batch is commited' do
        # person
         Mara::Batch.in_batch do
          person.save
          expect(person.exist?).to eq false
        end
        expect(person.exist?).to eq true
      end
    end
  end

  describe '#destroy' do
    context 'given a valid record' do
      let(:person) do
        object = Person.build(
          partition_key: SecureRandom.uuid,
          sort_key: Time.now.utc.to_f.to_s,
          first_name: 'Maddie',
          last_name: 'Schipper'
        )
        object.save!
        object
      end

      it { expect { person.destroy! }.to_not raise_error }
    end
  end

  describe '#destroy' do
    context 'given a valid record' do
      let(:person) do
        object = Person.build(
          partition_key: SecureRandom.uuid,
          sort_key: Time.now.utc.to_f.to_s,
          first_name: 'Maddie',
          last_name: 'Schipper'
        )
        object.save!
        object
      end

      it { expect(person.destroy).to eq true }
    end
  end

  describe '#find' do
    context 'given a valid record' do
      let(:person) do
        object = Person.build(
          partition_key: SecureRandom.uuid,
          sort_key: Time.now.utc.to_f.to_s,
          first_name: 'Maddie',
          last_name: 'Schipper'
        )
        object.save!
        object
      end

      subject { Person.find(person.partition_key, person.sort_key) }

      it 'finds without an error' do
        expect { subject }.to_not raise_error
      end

      it { expect(subject).to be_a(Person) }

      it { expect(subject.partition_key).to eq person.partition_key }

      it { expect(subject.sort_key).to eq person.sort_key }

      it { expect(subject.first_name).to eq 'Maddie' }

      it { expect(subject.last_name).to eq 'Schipper' }
    end

    context 'given a nil sort key' do
      it 'raises and error' do
        expect { Person.find('foo', nil) }.to raise_error(ArgumentError) do |error|
          expect(error.message).to eq 'Class specifies a sort key, but no sort key value was given.'
        end
      end
    end

    context 'given a nil partition key' do
      it 'raises and error' do
        expect { Person.find(nil, nil) }.to raise_error(ArgumentError) do |error|
          expect(error.message).to eq 'Must specify a valid partition key value'
        end
      end
    end

    context 'given a blank partition key' do
      it 'raises and error' do
        expect { Person.find('', nil) }.to raise_error(ArgumentError) do |error|
          expect(error.message).to eq 'Must specify a valid partition key value'
        end
      end
    end
  end
end
