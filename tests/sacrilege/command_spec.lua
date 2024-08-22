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

    describe("copy", function()
        local function test(cmd)
            local copy = cmd:copy()

            assert(cmd.name       == copy.name)
            assert(cmd.definition ~= copy.definition or type(copy.definition) ~= "table")
            assert(cmd.definition == (copy.definition and copy.definition.linked))
        end

        it("should create a linked command from a nil command", function()
            test(command.new("Nil Command"))
        end)

        it("should create a linked command from a string command", function()
            test(command.new("String Command", "<Cmd><CR>"))
        end)

        it("should create a linked command from a table command", function()
            test(command.new("Table Command", { }))
        end)
    end)

    describe("clone", function()
        local function test(cmd)
            local clone = cmd:clone()

            assert(cmd.name       == clone.name)
            assert(cmd.definition ~= clone.definition or type(clone.definition) ~= "table")
            assert(nil            == (clone.definition and clone.definition.linked))
            assert.are.same(cmd.definition, clone.definition)
        end

        it("should create an unlinked command from a nil command", function()
            test(command.new("Nil Command"))
        end)

        it("should create an unlinked command from a string command", function()
            test(command.new("String Command", "<Cmd><CR>"))
        end)

        it("should create an unlinked command from a table command", function()
            test(command.new("Table Command", { }))
        end)
    end)
end)
