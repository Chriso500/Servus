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
        Logger.info "ERROR Checking PRAGMA from Table #{table}"
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
        case Sqlitex.Server.exec(db, "ALTER TABLE #{table} ADD COLUMN #{x.columnName} #{x.columnType}") do
          :ok -> Logger.info "Table #{table} added missing column #{x.columnName}"
          _-> 
            Logger.info "Error Table #{table} adding missing column #{x.columnName}"
        end
      end
    end)
  end

end
