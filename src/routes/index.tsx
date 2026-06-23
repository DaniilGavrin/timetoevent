import { createFileRoute } from '@tanstack/react-router';
import { invoke } from '@tauri-apps/api/core';
import { useState, useEffect } from 'react';

export const Route = createFileRoute('/')({
  component: Index,
});

function Index() {
  const [localIp, setLocalIp] = useState<string>('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    invoke<string>('get_local_ip')
      .then(setLocalIp)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8">
      <div className="card max-w-md w-full text-center">
        <h1 className="text-3xl font-bold mb-4">TimeToEvent</h1>
        <p className="text-muted-foreground mb-6">
          Локальный трекер событий с синхронизацией между устройствами
        </p>
        
        <div className="bg-secondary/50 rounded-lg p-4 mb-6">
          <p className="text-sm text-muted-foreground mb-1">Локальный IP:</p>
          <p className="text-lg font-mono font-bold">
            {loading ? 'Загрузка...' : localIp || 'Не удалось определить'}
          </p>
        </div>

        <div className="space-y-3">
          <button className="btn-primary w-full">
            Создать событие
          </button>
          <button className="btn-secondary w-full">
            Синхронизация устройств
          </button>
        </div>
      </div>
    </main>
  );
}