import { useState, useEffect, useRef } from 'react';

interface TimerState {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
  totalSeconds: number;
  isPast: boolean;
  formatted: string;
}

export function useTimer(eventDate: number, eventType: 'countdown' | 'countup'): TimerState {
  const [now, setNow] = useState(() => Math.floor(Date.now() / 1000));
  const intervalRef = useRef<number | null>(null);

  useEffect(() => {
    // Если событие уже прошло на момент монтирования — интервал не запускаем
    const initialNow = Math.floor(Date.now() / 1000);
    if (eventType === 'countdown' && eventDate <= initialNow) {
      setNow(initialNow);
      return;
    }

    intervalRef.current = window.setInterval(() => {
      const currentNow = Math.floor(Date.now() / 1000);
      setNow(currentNow);

      // ⭐ КЛЮЧЕВОЕ: останавливаем тиканье, когда countdown завершился
      if (eventType === 'countdown' && eventDate <= currentNow) {
        if (intervalRef.current) {
          clearInterval(intervalRef.current);
          intervalRef.current = null;
        }
      }
    }, 1000);

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };
  }, [eventDate, eventType]);

  const diff = eventType === 'countdown' ? eventDate - now : now - eventDate;
  const isPast = eventType === 'countdown' ? diff < 0 : false;
  const totalSeconds = Math.abs(diff);

  const days = Math.floor(totalSeconds / 86400);
  const hours = Math.floor((totalSeconds % 86400) / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  // ⭐ Если countdown и событие прошло — показываем статус, а не минус
  const formatted =
    isPast && eventType === 'countdown'
      ? 'Прошло событие'
      : formatTimer(days, hours, minutes, seconds, eventType);

  return { days, hours, minutes, seconds, totalSeconds, isPast, formatted };
}

function formatTimer(
  days: number,
  hours: number,
  minutes: number,
  seconds: number,
  eventType: 'countdown' | 'countup',
): string {
  const parts: string[] = [];
  if (days > 0) parts.push(`${days}д`);
  if (hours > 0 || days > 0) parts.push(`${hours}ч`);
  parts.push(`${minutes}м`);
  parts.push(`${seconds}с`);

  const result = parts.join(' ');
  return eventType === 'countup' ? `${result} назад` : result;
}