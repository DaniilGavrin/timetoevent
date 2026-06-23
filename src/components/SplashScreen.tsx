import { motion } from 'framer-motion';
import { Clock } from 'lucide-react';

export function SplashScreen() {
  return (
    <motion.div
      className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-gradient-to-br from-background via-secondary to-background"
      initial={{ opacity: 1 }}
      exit={{ opacity: 0, scale: 1.1 }}
      transition={{ duration: 0.8, ease: 'easeInOut' }}
    >
      {/* Фоновые пульсирующие кольца */}
      <div className="absolute inset-0 flex items-center justify-center overflow-hidden">
        {[0, 1, 2].map((i) => (
          <motion.div
            key={i}
            className="absolute rounded-full border-2 border-primary/20"
            initial={{ width: 0, height: 0, opacity: 0 }}
            animate={{
              width: [0, 400, 800],
              height: [0, 400, 800],
              opacity: [0, 0.5, 0],
            }}
            transition={{
              duration: 3,
              repeat: Infinity,
              delay: i * 1,
              ease: 'easeOut',
            }}
          />
        ))}
      </div>

      {/* Логотип с часами */}
      <motion.div
        className="relative mb-8"
        initial={{ scale: 0, rotate: -180 }}
        animate={{ scale: 1, rotate: 0 }}
        transition={{ duration: 0.8, type: 'spring', stiffness: 100 }}
      >
        {/* Свечение за иконкой */}
        <motion.div
          className="absolute inset-0 bg-primary/30 blur-3xl rounded-full"
          animate={{
            scale: [1, 1.2, 1],
            opacity: [0.3, 0.5, 0.3],
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
        
        {/* Иконка часов */}
        <div className="relative w-24 h-24 flex items-center justify-center bg-primary/10 rounded-3xl border-2 border-primary/30 backdrop-blur-sm">
          <Clock className="w-12 h-12 text-primary" strokeWidth={2} />
          
          {/* Вращающаяся стрелка */}
          <motion.div
            className="absolute w-1 h-8 bg-primary rounded-full origin-bottom"
            style={{ bottom: '50%', left: 'calc(50% - 2px)' }}
            animate={{ rotate: 360 }}
            transition={{
              duration: 2,
              repeat: Infinity,
              ease: 'linear',
            }}
          />
        </div>
      </motion.div>

      {/* Название приложения */}
      <motion.div
        className="text-center relative z-10"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.5 }}
      >
        <motion.h1
          className="text-4xl font-bold bg-gradient-to-r from-primary via-accent to-primary bg-clip-text text-transparent"
          animate={{
            backgroundPosition: ['0% 50%', '100% 50%', '0% 50%'],
          }}
          transition={{
            duration: 3,
            repeat: Infinity,
            ease: 'linear',
          }}
          style={{
            backgroundSize: '200% 200%',
          }}
        >
          TimeToEvent
        </motion.h1>
        
        <motion.p
          className="text-muted-foreground mt-2 text-sm"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.8 }}
        >
          Трекер событий и напоминаний
        </motion.p>
      </motion.div>

      {/* Индикатор загрузки */}
      <motion.div
        className="mt-12 flex gap-2"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.6, delay: 1 }}
      >
        {[0, 1, 2].map((i) => (
          <motion.div
            key={i}
            className="w-2 h-2 bg-primary rounded-full"
            animate={{
              scale: [1, 1.5, 1],
              opacity: [0.3, 1, 0.3],
            }}
            transition={{
              duration: 1,
              repeat: Infinity,
              delay: i * 0.2,
              ease: 'easeInOut',
            }}
          />
        ))}
      </motion.div>
    </motion.div>
  );
}