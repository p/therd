assert = require 'assert'
phpbb = require '../src/phpbb'

d = console.log

assert_arrays_equal = (one, two)->
  assert.equal(one.length, two.length)
  for index in [0...one.length]
    assert.strictEqual one[index], two[index]

assert_arrays_equal_unordered = (one, two)->
  # http://www.xenoveritas.org/blog/xeno/the-correct-way-to-clone-javascript-arrays
  one = one.slice(0)
  one.sort()
  two = two.slice(0)
  two.sort()
  d one, two
  assert_arrays_equal one, two

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
  
  it 'should explode again correctly', ->
    check = (args)->
      [scope, expected] = args
      exploded = phpbb.explode_scope2 scope
      #assert_arrays_equal_unordered expected, exploded
      assert.equal JSON.stringify(expected), JSON.stringify(exploded)
    
    [
      [
        ['postgres', 'unit']
        [
          ['unit', 'postgres']
        ]
      ]
      [
        ['postgres', 'mysql', 'unit']
        [
          ['unit', 'postgres']
          ['unit', 'mysql']
        ]
      ]
      [
        ['postgres', 'unit', 'functional']
        [
          ['unit', 'postgres']
          ['functional', 'postgres']
        ]
      ]
    ].map check
