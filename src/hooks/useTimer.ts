import { useState, useEffect } from 'react';

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

  useEffect(() => {
    const interval = setInterval(() => {
      setNow(Math.floor(Date.now() / 1000));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const diff = eventType === 'countdown' ? eventDate - now : now - eventDate;
  const isPast = eventType === 'countdown' ? diff < 0 : false;
  const totalSeconds = Math.abs(diff);

  const days = Math.floor(totalSeconds / 86400);
  const hours = Math.floor((totalSeconds % 86400) / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  const formatted = formatTimer(days, hours, minutes, seconds, eventType, isPast);

  return { days, hours, minutes, seconds, totalSeconds, isPast, formatted };
}

function formatTimer(
  days: number,
  hours: number,
  minutes: number,
  seconds: number,
  eventType: 'countdown' | 'countup',
  isPast: boolean,
): string {
  const parts: string[] = [];
  if (days > 0) parts.push(`${days}д`);
  if (hours > 0 || days > 0) parts.push(`${hours}ч`);
  parts.push(`${minutes}м`);
  parts.push(`${seconds}с`);

  const result = parts.join(' ');
  if (eventType === 'countup') return `${result} назад`;
  if (isPast) return `-${result}`;
  return result;
}