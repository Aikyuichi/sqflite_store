## 0.2.0
#### New functions in Database class
* *checkForeignKeys()*: Checks the database, or a table, for foreign key constraints that are violated.
* *checkIntegrity()*: It does a low-level formatting and consistency check of the database.
* *getForeignKeys()*: Returns the foreign key constraints of a given table.
* *getIndexes()*: Returns the indexes associated with the given table.
* *getIndexInfo()*: Returns the key columns in a index.
* *getTableInfo()*: Returns the columns in a table.
* *getTables()*: Returns information about tables and views in a schema.
* *optimize()*: Attempt to optimize the database, or a specified schema.
## 0.1.1
* Fixes an error when calling the *closeDbStore()* function
## 0.1.0
* The function *registerDbAsset()* accepts the optional parameter *defaultDb*. This parameter allows to set the default database to use.
* The function *getDatabase()* accepts the optional parameter *key*. If key is omitted the function returns the default database.
## 0.0.1
* Initial release.
