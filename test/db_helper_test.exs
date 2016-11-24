defmodule DB_Helper_Test do
  use ExUnit.Case
  alias Servus.Serverutils
  alias Servus.Message
  require Logger

   @config Application.get_env(:servus, :database)
  #No Testmode memory for player
  @db "file:#{@config.rootpath}/db_helper.sqlite3#{@config.testmode}"

setup_all do
    {:ok, db} = Sqlitex.Server.start_link(@db)
    {:ok, %{db: db}}
  end

  test "standalone test for DB_Helper", context do
    assert :ok =  Sqlitex.Server.exec(context.db, "CREATE TABLE DB_HELPER_TEST (test1 TEXT)")
    Servus.SQLLITE_DB_Helper.findAndAddMissingColumns(context.db,[%{columnName: "email2", columnType: "TEXT" },%{columnName: "passwortMD5Hash", columnType: "TEXT" }],"DB_HELPER_TEST")
    case Sqlitex.Server.query(context.db, "PRAGMA table_info('DB_HELPER_TEST')")  do
     {:ok, result} -> 
        assert Enum.at(result,0)[:name] == "test1"
        assert Enum.at(result,0)[:type] == "TEXT"
        assert Enum.at(result,1)[:name] == "email2"
        assert Enum.at(result,1)[:type] == "TEXT"
        assert Enum.at(result,2)[:name] == "passwortMD5Hash"
        assert Enum.at(result,2)[:type] == "TEXT"
        assert Enum.at(result,3)==nil
      end
    end
end
