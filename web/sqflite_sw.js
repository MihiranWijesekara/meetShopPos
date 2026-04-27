// Sqflite Service Worker
console.log('[sqflite_sw] Service worker initializing...');

let db;
let initPromise;

// Import sql.js
importScripts('https://sql.js.org/dist/sql-wasm.js');

self.oninstall = function() {
  console.log('[sqflite_sw] Service worker installed');
};

self.onactivate = function() {
  console.log('[sqflite_sw] Service worker activated');
};

self.onmessage = async function(event) {
  const { method, args, id } = event.data;
  
  try {
    // Initialize sql.js if needed
    if (!initPromise) {
      initPromise = initSqlJs({
        locateFile: file => `https://sql.js.org/dist/${file}`
      });
    }

    let result;
    const SQL = await initPromise;

    switch (method) {
      case 'open':
        if (!db) {
          db = new SQL.Database();
          console.log('[sqflite_sw] Database opened');
        }
        result = { success: true };
        break;

      case 'execute':
        if (!db) {
          throw new Error('Database not open');
        }
        const [sql, params = []] = args;
        db.run(sql, params);
        result = { success: true };
        break;

      case 'query':
        if (!db) {
          throw new Error('Database not open');
        }
        const [querySql, queryParams = []] = args;
        const stmt = db.prepare(querySql);
        stmt.bind(queryParams);
        const results = [];
        while (stmt.step()) {
          results.push(stmt.getAsObject());
        }
        stmt.free();
        result = results;
        break;

      case 'close':
        if (db) {
          db.close();
          db = null;
          console.log('[sqflite_sw] Database closed');
        }
        result = { success: true };
        break;

      default:
        throw new Error(`Unknown method: ${method}`);
    }

    event.ports[0].postMessage({ id, result });
  } catch (error) {
    console.error('[sqflite_sw] Error:', error);
    event.ports[0].postMessage({ id, error: error.message });
  }
};

console.log('[sqflite_sw] Service worker loaded');
