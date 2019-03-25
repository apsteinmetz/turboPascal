{
Here is Terje's code converted to a form TP V4.0 - V6.0 can handle.

The function can handle a hex string from 1 to 8 bytes long, except for the
$FFFFFFFF value (= -1). I process 2 chars each time trough the main loop, to
avoid the overhead from shifting a 32-bit value 4 bits left:
}

Function DeHex(InStr:STRING): LongInt;
Inline(
  $FC          {    cld              }
  /$5E         {    pop  si          }
  /$58         {    pop  ax          }
  /$1E         {    push ds          }
  /$8E/$D8     {    mov  ds,ax       }
  /$AC         {    lodsb            }
  /$30/$E4     {    xor  ah,ah       }
  /$09/$C0     {    or   ax,ax       }
  /$74/$53     {    jz   error       }
  /$31/$D2     {    xor  dx,dx       }
  /$31/$DB     {    xor  bx,bx       }
               {                     }
  /$B1/$04     {    mov  cl,4        }
               {                     }
  /$89/$C7     {    mov  di,ax       }
  /$47         {    inc  di          }
  /$D1/$EF     {    shr  di,1        }
  /$73/$23     {    jnc  l2          }
               {                     }
               {l0:                  }
  /$88/$D6     {    mov  dh,dl       }
  /$88/$FA     {    mov  dl,bh       }
  /$88/$DF     {    mov  bh,bl       }
               {                     }
  /$AC         {    lodsb            }
  /$2C/$30     {    sub  al,'0'      }
  /$72/$3B     {    jb   error       }
  /$3C/$09     {    cmp  al,9        }
  /$76/$10     {    jbe  l1          }
  /$2C/$07     {    sub  al,'A'-'9'-1}
  /$72/$33     {    jb   error       }
  /$3C/$0F     {    cmp  al,15       }
  /$76/$08     {    jbe  l1          }
  /$2C/$20     {    sub  al,32       }
  /$72/$2B     {    jb   error       }
  /$3C/$0F     {    cmp  al,15       }
  /$77/$27     {    ja   error       }
               {l1:                  }
  /$D2/$E0     {    shl  al,cl       }
  /$88/$C3     {    mov  bl,al       }
               {                     }
               {l2:                  }
  /$AC         {    lodsb            }
  /$2C/$30     {    sub  al,'0'      }
  /$72/$1E     {    jb   error       }
  /$3C/$09     {    cmp  al,9        }
  /$76/$10     {    jbe  l3          }
  /$2C/$07     {    sub  al,'A'-'9'-1}
  /$72/$16     {    jb   error       }
  /$3C/$0F     {    cmp  al,15       }
  /$76/$08     {    jbe  l3          }
  /$2C/$20     {    sub  al,32       }
  /$72/$0E     {    jb   error       }
  /$3C/$0F     {    cmp  al,15       }
  /$77/$0A     {    ja   error       }
               {                     }
               {l3:                  }
  /$08/$C3     {    or   bl,al       }
  /$4F         {    dec  di          }
  /$75/$BF     {    jnz  l0          }
               {                     }
  /$89/$D8     {    mov  ax,bx       }
  /$E9/$05/$00 {    jmp  done        }
               {                     }
               {error:               }
  /$B8/$FF/$FF {    mov  ax,-1       }
  /$89/$C2     {    mov  dx,ax       }
               {done:                }
  /$1F         {    pop  ds          }
);

