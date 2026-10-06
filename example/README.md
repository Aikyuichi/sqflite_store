# sqflite_store Example App

This example project demonstrates the usage of the `sqflite_store` package.

## Features Demonstrated

1. **Asset Database Registration**: Registering `assets/main.sqlite` using `registerDbAsset` with `copy: 'once'`.
2. **Database Queries**: Reading and updating a counter value stored in SQLite.
3. **Database Extensions & PRAGMAs**:
   - Inspecting tables via `db.getTables()` (PRAGMA `table_list`).
   - Checking database version (`db.getVersion()`).
   - Verifying database integrity via `db.checkIntegrity(quick: true)`.
4. **Lifecycle Management**: Closing active database connections on app pause using `closeDbStore()`.

## Running the Example

```bash
flutter run
```
