import React from 'react';
import clsx from 'clsx';

interface MascotProps {
  type: 'idle' | 'thinking' | 'success' | 'error';
  className?: string;
}

export const Mascot: React.FC<MascotProps> = ({ type, className }) => {
  return (
    <svg 
      viewBox="0 0 100 100" 
      className={clsx("overflow-visible", className)}
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur stdDeviation="2" result="blur" />
          <feComposite in="SourceGraphic" in2="blur" operator="over" />
        </filter>
      </defs>

      {/* Bounce Animation Group */}
      <g className={type === 'thinking' ? 'animate-bounce' : ''}>
        
        {/* Antenna */}
        <path d="M50 30 L50 15" stroke="#38bdf8" strokeWidth="4" strokeLinecap="round" />
        <circle cx="50" cy="15" r="5" fill="#fbbf24" className={type === 'thinking' ? 'animate-pulse' : ''} />

        {/* Body/Head */}
        <rect x="20" y="30" width="60" height="50" rx="16" fill="#38bdf8" />
        <rect x="20" y="30" width="60" height="50" rx="16" fill="url(#grad1)" fillOpacity="0.5" />
        
        {/* Shadow/Detail */}
        <path d="M25 35 H75" stroke="#7dd3fc" strokeWidth="2" strokeLinecap="round" opacity="0.5" />

        {/* Face Screen */}
        <rect x="30" y="42" width="40" height="26" rx="8" fill="#f0f9ff" />

        {/* Expressions */}
        {type === 'idle' && (
          <g transform="translate(0, 1)">
            <circle cx="42" cy="53" r="3.5" fill="#0284c7" />
            <circle cx="58" cy="53" r="3.5" fill="#0284c7" />
            <path d="M46 60 Q50 63 54 60" stroke="#0284c7" strokeWidth="2" strokeLinecap="round" fill="none" />
            {/* Blush */}
            <circle cx="36" cy="58" r="2" fill="#f472b6" opacity="0.6" />
            <circle cx="64" cy="58" r="2" fill="#f472b6" opacity="0.6" />
          </g>
        )}

        {type === 'thinking' && (
          <g>
            <circle cx="42" cy="53" r="3.5" fill="#0284c7" />
            <circle cx="58" cy="53" r="3.5" fill="#0284c7" />
            <path d="M46 60 H54" stroke="#0284c7" strokeWidth="2" strokeLinecap="round" />
            {/* Gear Orbiting */}
            <g className="origin-center animate-[spin_3s_linear_infinite]" style={{ transformBox: 'fill-box', transformOrigin: '50% 50%' }}>
               <path d="M85 20 L95 20 M90 15 L90 25 M86.5 16.5 L93.5 23.5 M86.5 23.5 L93.5 16.5" stroke="#fbbf24" strokeWidth="3" strokeLinecap="round" />
            </g>
          </g>
        )}

        {type === 'success' && (
          <g>
            {/* Happy Eyes (^) */}
            <path d="M39 53 L42 50 L45 53" stroke="#0284c7" strokeWidth="2.5" strokeLinecap="round" fill="none" />
            <path d="M55 53 L58 50 L61 53" stroke="#0284c7" strokeWidth="2.5" strokeLinecap="round" fill="none" />
            <path d="M45 60 Q50 65 55 60" stroke="#0284c7" strokeWidth="2.5" strokeLinecap="round" fill="none" />
            
            {/* Arms up */}
            <path d="M20 55 Q10 45 15 35" stroke="#38bdf8" strokeWidth="5" strokeLinecap="round" fill="none" />
            <path d="M80 55 Q90 45 85 35" stroke="#38bdf8" strokeWidth="5" strokeLinecap="round" fill="none" />
          </g>
        )}

        {type === 'error' && (
          <g>
            {/* X Eyes */}
            <path d="M39 50 L45 56 M45 50 L39 56" stroke="#ef4444" strokeWidth="2" strokeLinecap="round" />
            <path d="M55 50 L61 56 M61 50 L55 56" stroke="#ef4444" strokeWidth="2" strokeLinecap="round" />
            <path d="M46 62 Q50 58 54 62" stroke="#ef4444" strokeWidth="2" strokeLinecap="round" fill="none" />
            
            {/* Bandage */}
            <rect x="25" y="25" width="14" height="6" rx="2" fill="#fca5a5" transform="rotate(-15 25 25)" />
          </g>
        )}
      </g>
      
      {/* Decorative Elements */}
      {type === 'success' && (
         <g className="animate-pulse">
            <path d="M10 20 L15 25 M12 28 L18 20" stroke="#fbbf24" strokeWidth="2" strokeLinecap="round" />
            <path d="M85 10 L90 15 M87 18 L93 10" stroke="#fbbf24" strokeWidth="2" strokeLinecap="round" />
         </g>
      )}
    </svg>
  );
};