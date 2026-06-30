import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Shield, AlertCircle } from 'lucide-react';
import { useDevicesStore } from '../../stores/devicesStore';

interface PairingDialogProps {
  isOpen: boolean;
  onClose: () => void;
}

export function PairingDialog({ isOpen, onClose }: PairingDialogProps) {
  const [code, setCode] = useState('');
  const {
    pairingCode,
    pairingError,
    pairingLoading,
    verifyPairingCode,
    cancelPairing,
  } = useDevicesStore();

  const handleClose = () => {
    setCode('');
    onClose();
  };

  const handleCancel = async () => {
    await cancelPairing();
    handleClose();
  };

  const handleVerify = async () => {
    if (code.length !== 6) return;
    const success = await verifyPairingCode(code);
    if (success) {
      handleClose();
    }
  };

  const handleCodeChange = (value: string) => {
    const cleaned = value.replace(/\D/g, '').slice(0, 6);
    setCode(cleaned);
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleCancel}
          />

          <motion.div
            className="fixed inset-0 z-50 flex items-center justify-center p-4 pointer-events-none"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ duration: 0.2 }}
          >
            <div className="card max-w-md w-full pointer-events-auto">
              <div className="flex items-start justify-between mb-6">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
                    <Shield className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <h2 className="text-xl font-bold">Подтверждение сопряжения</h2>
                    <p className="text-sm text-muted-foreground mt-0.5">
                      Введите код для установления соединения
                    </p>
                  </div>
                </div>
                <button
                  onClick={handleCancel}
                  className="p-2 hover:bg-secondary rounded-lg transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {pairingCode && (
                <div className="mb-6">
                  <p className="text-sm text-muted-foreground mb-2">
                    Код для ввода на другом устройстве:
                  </p>
                  <div className="bg-secondary rounded-lg p-4 text-center">
                    <p className="text-4xl font-mono font-bold tracking-wider text-foreground">
                      {pairingCode}
                    </p>
                  </div>
                  <p className="text-xs text-muted-foreground mt-2">
                    💡 Убедитесь, что коды на обоих устройствах совпадают
                  </p>
                </div>
              )}

              <div className="mb-6">
                <label className="text-sm font-medium mb-2 block">
                  Введите код с другого устройства:
                </label>
                <input
                  type="text"
                  value={code}
                  onChange={(e) => handleCodeChange(e.target.value)}
                  placeholder="000000"
                  maxLength={6}
                  className="w-full px-4 py-3 bg-secondary rounded-lg border border-border text-center text-2xl font-mono font-bold tracking-wider focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary/30 transition-all"
                  disabled={pairingLoading}
                  autoFocus
                />
                {code.length > 0 && code.length < 6 && (
                  <p className="text-xs text-muted-foreground mt-1">
                    Осталось цифр: {6 - code.length}
                  </p>
                )}
              </div>

              {pairingError && (
                <motion.div
                  className="mb-4 p-3 bg-destructive/10 border border-destructive/20 rounded-lg flex items-start gap-2"
                  initial={{ opacity: 0, y: -8 }}
                  animate={{ opacity: 1, y: 0 }}
                >
                  <AlertCircle className="w-5 h-5 text-destructive flex-shrink-0 mt-0.5" />
                  <p className="text-sm text-destructive">{pairingError}</p>
                </motion.div>
              )}

              <div className="flex gap-3">
                <motion.button
                  onClick={handleCancel}
                  className="btn-secondary flex-1"
                  disabled={pairingLoading}
                  whileHover={{ scale: 1.01 }}
                  whileTap={{ scale: 0.98 }}
                >
                  Отмена
                </motion.button>
                <motion.button
                  onClick={handleVerify}
                  disabled={code.length !== 6 || pairingLoading}
                  className="btn-primary flex-1 disabled:opacity-50 disabled:cursor-not-allowed"
                  whileHover={{ scale: code.length === 6 && !pairingLoading ? 1.01 : 1 }}
                  whileTap={{ scale: code.length === 6 && !pairingLoading ? 0.98 : 1 }}
                >
                  {pairingLoading ? (
                    <span className="flex items-center justify-center gap-2">
                      <motion.div
                        className="w-4 h-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full"
                        animate={{ rotate: 360 }}
                        transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
                      />
                      Проверка...
                    </span>
                  ) : (
                    'Подтвердить'
                  )}
                </motion.button>
              </div>

              <div className="mt-4 p-3 bg-secondary/50 rounded-lg">
                <p className="text-xs text-muted-foreground">
                  🔒 Это защита от MITM-атак. Если коды не совпадают — кто-то пытается перехватить соединение.
                </p>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}