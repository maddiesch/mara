require 'spec_helper'

RSpec.describe  Mara::Table do
  let(:table_name) { SecureRandom.uuid }

  before { allow( Mara::Table).to receive(:log) }

  after {  Mara::Table.teardown!(table_name: table_name) }

  describe '#prepare!' do
    let(:table_params) do
      {
        table_name: table_name,
        attribute_definitions: [
          {
            attribute_name: 'PrimaryKey',
            attribute_type: 'S'
          }
        ],
        key_schema: [
          {
            attribute_name: 'PrimaryKey',
            key_type: 'HASH'
          }
        ]
      }
    end

    context 'given valid table params' do
      it { expect {  Mara::Table.prepare!(table_params) }.to_not raise_error }
    end

    context 'given a non-supported environment' do
      before do
        expect( Mara.config).to receive(:env).and_return('production')
        expect( Mara.config).to receive(:env).and_return('test')
      end

      it 'raises an error' do
        expect {  Mara::Table.prepare!(table_params) }.to raise_error(ArgumentError) do |error|
          expect(error.message).to eq "Can't prepare table outside of development/test"
        end
      end
    end

    context 'given an already existing table' do
      it "doesn't call create_table the second time" do
        expect( Mara::Client.shared).to receive(:create_table).and_call_original
         Mara::Table.prepare!(table_params)
        expect( Mara::Client.shared).to_not receive(:create_table)
         Mara::Table.prepare!(table_params)
      end
    end
  end
end
