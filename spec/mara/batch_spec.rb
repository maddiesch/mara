require 'spec_helper'

RSpec.describe  Mara::Batch do
  context  Mara::Rollback do
    it 'aborts the batch without an error' do
      expect do
         Mara::Batch.in_batch do
          raise  Mara::Rollback
        end
      end.to_not raise_error
    end

    it 'aborts the batch' do
      expect do
         Mara::Batch.in_batch do
          raise StandardError, 'Testing Rollback'
        end
      end.to raise_error(StandardError) do |error|
        expect(error.message).to eq 'Testing Rollback'
      end
    end
  end
end
