assert = require 'assert'
phpbb = require '../src/phpbb'

d = console.log

assert_arrays_equal = (one, two)->
  assert.equal(one.length, two.length)
  assert.strictEqual one[index], two[index] for index in [0...one.length]

describe 'scope', ->
  it 'should explode correctly', ->
    check = (args)->
      [scope, expected] = args
      exploded = phpbb.explode_scope scope
      assert_arrays_equal expected, exploded
    
    [
      [
        ['postgres', 'unit']
        ['unit-postgres']
      ]
      [
        ['postgres', 'mysql', 'unit']
        ['unit-postgres', 'unit-mysql']
      ]
      [
        ['postgres', 'unit', 'functional']
        ['unit-postgres', 'functional-postgres']
      ]
    ].map check
