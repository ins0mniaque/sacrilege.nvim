local command = require("sacrilege.command")

describe("command", function()
    describe("is", function()
        it("should return true for commands", function()
            local cmd = command.new("Test Command")

            assert.are.same(true, command.is(cmd))
        end)

        it("should return true for linked commands", function()
            local cmd = command.new("Test Command"):copy()

            assert.are.same(true, command.is(cmd))
        end)

        it("should return false for commands without metatable", function()
            local cmd = command.new("Test Command")

            setmetatable(cmd, nil)

            assert.are.same(false, command.is(cmd))
        end)

        it("should return false for tables", function()
            assert.are.same(false, command.is({ }))
        end)

        it("should return false for strings", function()
            assert.are.same(false, command.is("string"))
        end)

        it("should return false for numbers", function()
            assert.are.same(false, command.is(1))
        end)

        it("should return false for boolean", function()
            assert.are.same(false, command.is(true))
        end)

        it("should return false for nil", function()
            assert.are.same(false, command.is(nil))
        end)
    end)
end)
