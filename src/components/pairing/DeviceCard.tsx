import { motion } from 'framer-motion';
import { Smartphone, Monitor, Wifi, WifiOff, Trash2, Link2, Unlink } from 'lucide-react';
import type { Peer, DiscoveredPeer } from '../../lib/tauri';

interface DiscoveredDeviceCardProps {
  peer: DiscoveredPeer;
  onConnect: () => void;
  loading?: boolean;
}

export function DiscoveredDeviceCard({ peer, onConnect, loading }: DiscoveredDeviceCardProps) {
  const isDesktop = peer.device_info.toLowerCase().includes('desktop');
  const Icon = isDesktop ? Monitor : Smartphone;

  return (
    <motion.div
      className="card group hover:border-foreground/20 transition-colors"
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -12 }}
      transition={{ duration: 0.3 }}
    >
      <div className="flex items-start gap-4">
        <div className="w-12 h-12 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
          <Icon className="w-6 h-6 text-muted-foreground" />
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-base font-semibold truncate">{peer.name}</h3>
            <div className="flex items-center gap-1 px-2 py-0.5 bg-secondary rounded text-xs">
              <Wifi className="w-3 h-3 text-green-400" />
              <span className="text-green-400">Обнаружено</span>
            </div>
          </div>
          <p className="text-sm text-muted-foreground font-mono">
            {peer.ip}:{peer.port}
          </p>
          {peer.device_info && (
            <p className="text-xs text-muted-foreground mt-1">{peer.device_info}</p>
          )}
        </div>

        <motion.button
          onClick={onConnect}
          disabled={loading}
          className="btn-primary text-sm disabled:opacity-50 disabled:cursor-not-allowed"
          whileHover={{ scale: loading ? 1 : 1.02 }}
          whileTap={{ scale: loading ? 1 : 0.98 }}
        >
          {loading ? (
            <span className="flex items-center gap-2">
              <motion.div
                className="w-4 h-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full"
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
              />
              Подключение...
            </span>
          ) : (
            <span className="flex items-center gap-2">
              <Link2 className="w-4 h-4" />
              Подключить
            </span>
          )}
        </motion.button>
      </div>
    </motion.div>
  );
}

interface PairedDeviceCardProps {
  peer: Peer;
  isConnected: boolean;
  onDisconnect: () => void;
  onRemove: () => void;
  loading?: boolean;
}

export function PairedDeviceCard({
  peer,
  isConnected,
  onDisconnect,
  onRemove,
  loading,
}: PairedDeviceCardProps) {
  const lastSeenText = peer.last_seen
    ? new Date(peer.last_seen * 1000).toLocaleString('ru-RU')
    : 'Никогда';

  return (
    <motion.div
      className="card group hover:border-foreground/20 transition-colors"
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -12 }}
      transition={{ duration: 0.3 }}
    >
      <div className="flex items-start gap-4">
        <div className="w-12 h-12 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
          <Monitor className="w-6 h-6 text-muted-foreground" />
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-base font-semibold truncate">{peer.name}</h3>
            <div
              className={`flex items-center gap-1 px-2 py-0.5 rounded text-xs ${
                isConnected
                  ? 'bg-green-500/10 text-green-400'
                  : 'bg-secondary text-muted-foreground'
              }`}
            >
              {isConnected ? (
                <>
                  <Wifi className="w-3 h-3" />
                  <span>Онлайн</span>
                </>
              ) : (
                <>
                  <WifiOff className="w-3 h-3" />
                  <span>Оффлайн</span>
                </>
              )}
            </div>
          </div>
          <p className="text-sm text-muted-foreground">
            Последний раз: {lastSeenText}
          </p>
          <p className="text-xs text-muted-foreground mt-1 font-mono truncate">
            ID: {peer.id}
          </p>
        </div>

        <div className="flex gap-2">
          {isConnected && (
            <motion.button
              onClick={onDisconnect}
              disabled={loading}
              className="p-2 hover:bg-secondary rounded-lg transition-colors disabled:opacity-50"
              title="Отключить"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <Unlink className="w-4 h-4 text-muted-foreground" />
            </motion.button>
          )}
          <motion.button
            onClick={onRemove}
            disabled={loading}
            className="p-2 hover:bg-destructive/10 text-destructive rounded-lg transition-colors disabled:opacity-50"
            title="Удалить устройство"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <Trash2 className="w-4 h-4" />
          </motion.button>
        </div>
      </div>
    </motion.div>
  );
}