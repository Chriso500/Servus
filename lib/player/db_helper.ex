defmodule Servus.SQLLITE_DB_Helper do
  @moduledoc """
  
  """ 
  require Logger
  @doc """
  DB Helper function to add columns to an existing table
  this functions reads the content of the table with pragma sqllite command
  """
  def findAndAddMissingColumns(db, columnsCheck,table) do
   case Sqlitex.Server.query(db, "PRAGMA table_info('#{table}')")  do
     {:ok, result} -> 
        columnsAvaible = Enum.map result, fn(x) -> x[:name] end
        columnNameHelper(columnsAvaible,columnsCheck,db,table)
      _->
        Logger.error "ERROR Checking PRAGMA from Table #{table}"
    end
  end
  @doc """
  DB Helper function to add columns to an existing table
  this is the helperfunction to check two lists and add the missing columns to the given table
  """
  def columnNameHelper(columnsAvaible,columnsCheck,db,table) do
   columnsToCreate=Enum.map(columnsCheck, fn(x) ->
     innervalue = Enum.find(columnsAvaible, fn(y) ->
      if x.columnName == y do
        x
      end
   end)
     if innervalue == nil do
        x
      end
   end)
   Enum.each(columnsToCreate, fn(x) ->
      if x != nil do
        result = Sqlitex.Server.exec(db, "ALTER TABLE #{table} ADD COLUMN #{x.columnName} #{x.columnType}")
        case result do
          :ok -> Logger.info "Table #{table} added missing column #{x.columnName}"
          if Enum.member?(x,:contraint) == true && x.constraint != nil && x.constraint == "UNIQUE" do
            result_constraint = Sqlitex.Server.exec(db, "Create Unique Index #{x.columnName}_ukey on #{table}(#{x.columnName})")
            case result_constraint do
              :ok -> Logger.info "Contraint for #{table} added for column #{x.columnName}"
               _-> 
                Logger.error "Error Table #{table} adding missing contraint #{x.columnName}_ukey Error: #{inspect result}"
            end
          end
          _-> 
            Logger.error "Error Table #{table} adding missing column #{x.columnName} Error: #{inspect result}"
        end
      end
    end)
  end

end
