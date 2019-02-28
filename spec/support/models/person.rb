class Person <  Mara::Model::Base
  primary_key 'PrimaryKey', 'RangeKey'

  add_lsi('local_secondary_index_1', 'LSI1_RangeKey')
  add_lsi('local_secondary_index_2', 'LSI2_RangeKey')

  add_gsi('global_secondary_index_1', 'GSI1_PrimaryKey', 'GSI1_RangeKey')
  add_gsi('global_secondary_index_2', 'GSI2_PrimaryKey')
end
