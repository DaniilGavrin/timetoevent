import { createFileRoute } from '@tanstack/react-router';
import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Wifi, Smartphone, RefreshCw, AlertCircle } from 'lucide-react';
import { useDevicesStore } from '../stores/devicesStore';
import { DiscoveredDeviceCard, PairedDeviceCard } from '../components/pairing/DeviceCard';
import { PairingDialog } from '../components/pairing/PairingDialog';
import { toast } from 'sonner';

export const Route = createFileRoute('/devices')({
  component: DevicesPage,
});

const pageVariants = {
  initial: { opacity: 0, y: 24, scale: 0.98 },
  animate: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: { duration: 0.5, ease: [0.22, 1, 0.36, 1] as const },
  },
  exit: {
    opacity: 0,
    y: -16,
    scale: 0.99,
    transition: { duration: 0.3, ease: [0.4, 0, 1, 1] as const },
  },
};

const headerVariants = {
  initial: { opacity: 0, x: -12 },
  animate: {
    opacity: 1,
    x: 0,
    transition: { duration: 0.4, delay: 0.05, ease: [0.22, 1, 0.36, 1] as const },
  },
};

const sectionVariants = {
  initial: { opacity: 0, y: 20 },
  animate: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.5, ease: [0.22, 1, 0.36, 1] as const },
  },
};

function DevicesPage() {
  const {
    discoveredPeers,
    pairedDevices,
    connectedPeerIds,
    loading,
    error,
    fetchAll,
    fetchDiscoveredPeers,
    fetchConnectedPeers,
    startPairing,
    removePeer,
    disconnectPeer,
  } = useDevicesStore();

  const [pairingDialogOpen, setPairingDialogOpen] = useState(false);
  const [connectingPeerId, setConnectingPeerId] = useState<string | null>(null);
  const [removingPeerId, setRemovingPeerId] = useState<string | null>(null);

  useEffect(() => {
    fetchAll();
  }, [fetchAll]);

  // Автообновление списка обнаруженных устройств каждые 2 секунды
  useEffect(() => {
    const interval = setInterval(() => {
      fetchDiscoveredPeers();
      fetchConnectedPeers();
    }, 2000);

    return () => clearInterval(interval);
  }, [fetchDiscoveredPeers, fetchConnectedPeers]);

  const handleConnect = async (peerName: string, ip: string, port: number) => {
    setConnectingPeerId(`${ip}:${port}`);
    try {
      // В MVP генерируем временный public key на фронте
      // В продакшене это должно делаться в Rust
      const mockPublicKey = btoa('mock-public-key-' + Date.now());
      await startPairing(peerName, mockPublicKey, 'Discovered via mDNS');
      setPairingDialogOpen(true);
    } catch (err) {
      toast.error(`Ошибка подключения: ${err}`);
    } finally {
      setConnectingPeerId(null);
    }
  };

  const handleDisconnect = async (peerId: string) => {
    setRemovingPeerId(peerId);
    try {
      await disconnectPeer(peerId);
      toast.success('Устройство отключено');
    } catch (err) {
      toast.error(`Ошибка отключения: ${err}`);
    } finally {
      setRemovingPeerId(null);
    }
  };

  const handleRemove = async (peerId: string, peerName: string) => {
    if (!confirm(`Удалить устройство "${peerName}"?`)) return;

    setRemovingPeerId(peerId);
    try {
      await removePeer(peerId);
      toast.success('Устройство удалено');
    } catch (err) {
      toast.error(`Ошибка удаления: ${err}`);
    } finally {
      setRemovingPeerId(null);
    }
  };

  return (
    <motion.main
      className="min-h-full overflow-y-auto"
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      <div className="container mx-auto px-6 py-8 max-w-4xl">
        {/* Заголовок */}
        <motion.div className="mb-8 flex items-center gap-4" variants={headerVariants}>
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500/20 to-cyan-500/10 border border-blue-500/20 flex items-center justify-center flex-shrink-0">
            <Wifi className="w-6 h-6 text-blue-400" />
          </div>
          <div className="flex-1">
            <h1 className="text-3xl font-bold">Устройства</h1>
            <p className="mt-1 text-muted-foreground">
              Управление подключёнными устройствами
            </p>
          </div>
          <motion.button
            onClick={() => fetchAll()}
            disabled={loading}
            className="p-2 hover:bg-secondary rounded-lg transition-colors disabled:opacity-50"
            title="Обновить"
            whileHover={{ scale: 1.05, rotate: 180 }}
            whileTap={{ scale: 0.95 }}
            transition={{ duration: 0.3 }}
          >
            <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
          </motion.button>
        </motion.div>

        {/* Ошибка */}
        {error && (
          <motion.div
            className="mb-6 p-4 bg-destructive/10 border border-destructive/20 rounded-lg flex items-start gap-3"
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <AlertCircle className="w-5 h-5 text-destructive flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="text-sm text-destructive font-medium">Ошибка загрузки</p>
              <p className="text-sm text-destructive/80 mt-1">{error}</p>
            </div>
          </motion.div>
        )}

        {/* Обнаруженные устройства */}
        <motion.div variants={sectionVariants} className="mb-8">
          <div className="flex items-center gap-2 mb-4">
            <Smartphone className="w-5 h-5 text-muted-foreground" />
            <h2 className="text-lg font-semibold">Обнаруженные устройства</h2>
            <span className="text-sm text-muted-foreground">({discoveredPeers.length})</span>
          </div>

          {discoveredPeers.length === 0 ? (
            <div className="card text-center py-8">
              <Wifi className="w-12 h-12 text-muted-foreground mx-auto mb-3 opacity-50" />
              <p className="text-muted-foreground">Устройства не обнаружены</p>
              <p className="text-sm text-muted-foreground mt-1">
                Убедитесь, что другие устройства с TimeToEvent в той же сети
              </p>
            </div>
          ) : (
            <div className="grid gap-3">
              <AnimatePresence mode="popLayout">
                {discoveredPeers.map((peer) => (
                  <DiscoveredDeviceCard
                    key={`${peer.ip}:${peer.port}`}
                    peer={peer}
                    onConnect={() => handleConnect(peer.name, peer.ip, peer.port)}
                    loading={connectingPeerId === `${peer.ip}:${peer.port}`}
                  />
                ))}
              </AnimatePresence>
            </div>
          )}
        </motion.div>

        {/* Доверенные устройства */}
        <motion.div variants={sectionVariants}>
          <div className="flex items-center gap-2 mb-4">
            <Wifi className="w-5 h-5 text-muted-foreground" />
            <h2 className="text-lg font-semibold">Доверенные устройства</h2>
            <span className="text-sm text-muted-foreground">({pairedDevices.length})</span>
          </div>

          {pairedDevices.length === 0 ? (
            <div className="card text-center py-8">
              <Wifi className="w-12 h-12 text-muted-foreground mx-auto mb-3 opacity-50" />
              <p className="text-muted-foreground">Нет доверенных устройств</p>
              <p className="text-sm text-muted-foreground mt-1">
                Подключите устройство из списка обнаруженных выше
              </p>
            </div>
          ) : (
            <div className="grid gap-3">
              <AnimatePresence mode="popLayout">
                {pairedDevices.map((peer) => (
                  <PairedDeviceCard
                    key={peer.id}
                    peer={peer}
                    isConnected={connectedPeerIds.includes(peer.id)}
                    onDisconnect={() => handleDisconnect(peer.id)}
                    onRemove={() => handleRemove(peer.id, peer.name)}
                    loading={removingPeerId === peer.id}
                  />
                ))}
              </AnimatePresence>
            </div>
          )}
        </motion.div>
      </div>

      <PairingDialog
        isOpen={pairingDialogOpen}
        onClose={() => setPairingDialogOpen(false)}
      />
    </motion.main>
  );
}