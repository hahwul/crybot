require "json"
require "../../providers/base"

module Crybot
  module Agent
    module Tools
      abstract class Tool
        abstract def name : String
        abstract def description : String
        abstract def parameters : Hash(String, JSON::Any)

        def execute(args : Hash(String, JSON::Any)) : String
          ""
        end

        def to_schema : Providers::ToolDef
          Providers::ToolDef.new(
            name: name,
            description: description,
            parameters: parameters,
          )
        end

        protected def get_string_arg(args : Hash(String, JSON::Any), key : String, default : String = "") : String
          value = args[key]?
          return default if value.nil?
          value.as_s? || default
        end

        protected def get_int_arg(args : Hash(String, JSON::Any), key : String, default : Int32 = 0) : Int32
          value = args[key]?
          return default if value.nil?
          value.as_i?.try(&.to_i32) || default
        end

        protected def get_bool_arg(args : Hash(String, JSON::Any), key : String, default : Bool = false) : Bool
          value = args[key]?
          return default if value.nil?
          value.as_bool? || default
        end
      end
    end
  end
end
