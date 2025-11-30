-- Unit tests for lua/mogra_toolchain/ui/core/functional.lua
local _ = require("mogra_toolchain.ui.core.functional")

describe("functional utilities", function()
  describe("identity", function()
    it("returns the same value", function()
      assert.equals(5, _.identity(5))
      assert.equals("hello", _.identity("hello"))
      local tbl = { a = 1 }
      assert.equals(tbl, _.identity(tbl))
    end)

    it("returns nil for nil", function()
      assert.is_nil(_.identity(nil))
    end)
  end)

  describe("map", function()
    it("transforms each element", function()
      local result = _.map(function(x)
        return x * 2
      end, { 1, 2, 3 })
      assert.same({ 2, 4, 6 }, result)
    end)

    it("returns empty table for empty input", function()
      local result = _.map(function(x)
        return x
      end, {})
      assert.same({}, result)
    end)

    it("preserves array indices", function()
      local result = _.map(function(x)
        return x .. "!"
      end, { "a", "b", "c" })
      assert.equals("a!", result[1])
      assert.equals("b!", result[2])
      assert.equals("c!", result[3])
    end)

    it("works with complex transformations", function()
      local tools = {
        { name = "tool1", version = 1 },
        { name = "tool2", version = 2 },
      }
      local names = _.map(function(t)
        return t.name
      end, tools)
      assert.same({ "tool1", "tool2" }, names)
    end)
  end)

  describe("filter", function()
    it("keeps elements matching predicate", function()
      local result = _.filter(function(x)
        return x > 2
      end, { 1, 2, 3, 4, 5 })
      assert.same({ 3, 4, 5 }, result)
    end)

    it("returns empty table when nothing matches", function()
      local result = _.filter(function(x)
        return x > 10
      end, { 1, 2, 3 })
      assert.same({}, result)
    end)

    it("returns all elements when all match", function()
      local result = _.filter(function(x)
        return x > 0
      end, { 1, 2, 3 })
      assert.same({ 1, 2, 3 }, result)
    end)

    it("works with object predicates", function()
      local tools = {
        { name = "a", installed = true },
        { name = "b", installed = false },
        { name = "c", installed = true },
      }
      local installed = _.filter(function(t)
        return t.installed
      end, tools)
      assert.equals(2, #installed)
      assert.equals("a", installed[1].name)
      assert.equals("c", installed[2].name)
    end)
  end)

  describe("each", function()
    it("calls function for each element", function()
      local sum = 0
      _.each(function(x)
        sum = sum + x
      end, { 1, 2, 3, 4 })
      assert.equals(10, sum)
    end)

    it("does nothing for empty list", function()
      local called = false
      _.each(function()
        called = true
      end, {})
      assert.is_false(called)
    end)

    it("receives correct values", function()
      local values = {}
      _.each(function(x)
        table.insert(values, x)
      end, { "a", "b", "c" })
      assert.same({ "a", "b", "c" }, values)
    end)
  end)

  describe("any", function()
    it("returns true if any element matches", function()
      local result = _.any(function(x)
        return x > 3
      end, { 1, 2, 3, 4, 5 })
      assert.is_true(result)
    end)

    it("returns false if no element matches", function()
      local result = _.any(function(x)
        return x > 10
      end, { 1, 2, 3 })
      assert.is_false(result)
    end)

    it("returns false for empty list", function()
      local result = _.any(function()
        return true
      end, {})
      assert.is_false(result)
    end)

    it("short-circuits on first match", function()
      local check_count = 0
      _.any(function(x)
        check_count = check_count + 1
        return x == 2
      end, { 1, 2, 3, 4, 5 })
      assert.equals(2, check_count)
    end)
  end)

  describe("compose", function()
    it("composes functions right to left", function()
      local add1 = function(x)
        return x + 1
      end
      local double = function(x)
        return x * 2
      end
      local composed = _.compose(add1, double) -- add1(double(x))
      assert.equals(7, composed(3)) -- add1(double(3)) = add1(6) = 7
    end)

    it("works with single function", function()
      local add1 = function(x)
        return x + 1
      end
      local composed = _.compose(add1)
      assert.equals(6, composed(5))
    end)

    it("supports multiple arguments", function()
      local add = function(a, b)
        return a + b
      end
      local double = function(x)
        return x * 2
      end
      local composed = _.compose(double, add)
      assert.equals(10, composed(2, 3)) -- double(add(2, 3)) = double(5) = 10
    end)

    it("supports multiple return values", function()
      local swap = function(a, b)
        return b, a
      end
      local add_one_each = function(a, b)
        return a + 1, b + 1
      end
      local composed = _.compose(add_one_each, swap)
      local a, b = composed(1, 2)
      assert.equals(3, a) -- swap(1,2) = (2,1), add_one_each = (3, 2)
      assert.equals(2, b)
    end)
  end)

  describe("partial", function()
    it("pre-fills first argument", function()
      local add = function(a, b)
        return a + b
      end
      local add5 = _.partial(add, 5)
      assert.equals(8, add5(3))
    end)

    it("pre-fills multiple arguments", function()
      local add3 = function(a, b, c)
        return a + b + c
      end
      local add_1_2 = _.partial(add3, 1, 2)
      assert.equals(6, add_1_2(3))
    end)

    it("works with no pre-filled arguments", function()
      local add = function(a, b)
        return a + b
      end
      local same = _.partial(add)
      assert.equals(5, same(2, 3))
    end)
  end)

  describe("prop", function()
    it("returns property accessor function", function()
      local getName = _.prop("name")
      assert.equals("test", getName({ name = "test" }))
    end)

    it("returns nil for missing property", function()
      local getMissing = _.prop("missing")
      assert.is_nil(getMissing({ name = "test" }))
    end)

    it("works with numeric keys", function()
      local getFirst = _.prop(1)
      assert.equals("a", getFirst({ "a", "b", "c" }))
    end)
  end)

  describe("keys", function()
    it("returns all keys", function()
      local result = _.keys({ a = 1, b = 2, c = 3 })
      table.sort(result)
      assert.same({ "a", "b", "c" }, result)
    end)

    it("returns empty table for empty input", function()
      local result = _.keys({})
      assert.same({}, result)
    end)

    it("includes numeric keys", function()
      local result = _.keys({ [1] = "a", [2] = "b", name = "test" })
      assert.equals(3, #result)
    end)
  end)

  describe("size", function()
    it("counts all keys", function()
      assert.equals(3, _.size({ a = 1, b = 2, c = 3 }))
    end)

    it("returns 0 for empty table", function()
      assert.equals(0, _.size({}))
    end)

    it("counts both numeric and string keys", function()
      assert.equals(4, _.size({ 1, 2, name = "test", value = 42 }))
    end)
  end)

  describe("T and F", function()
    it("T always returns true", function()
      assert.is_true(_.T())
      assert.is_true(_.T(1, 2, 3))
    end)

    it("F always returns false", function()
      assert.is_false(_.F())
      assert.is_false(_.F(1, 2, 3))
    end)
  end)

  describe("always", function()
    it("returns function that always returns the value", function()
      local always5 = _.always(5)
      assert.equals(5, always5())
      assert.equals(5, always5(1, 2, 3))
    end)

    it("works with nil", function()
      local alwaysNil = _.always(nil)
      assert.is_nil(alwaysNil())
    end)

    it("works with tables", function()
      local tbl = { a = 1 }
      local alwaysTbl = _.always(tbl)
      assert.equals(tbl, alwaysTbl())
    end)
  end)
end)
