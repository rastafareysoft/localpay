{*******************************************************}
{      Opciones de Depuración para FastMM               }
{ Para activar una opción, quita las llaves { }          }
{ Para desactivarla, pon las llaves de nuevo             }
{*******************************************************}

// -- MODO DE DEPURACIÓN COMPLETO --
// Activa la mayoría de las comprobaciones de seguridad y de fugas.
{$define FullDebugMode}

// -- REPORTE DE FUGAS DE MEMORIA --
// Asegura que se genere el informe de fugas al cerrar.
{$define EnableMemoryLeakReporting}

// -- ¡LA OPCIÓN MÁS IMPORTANTE PARA TI! --
// Registra la pila de llamadas en el momento de la asignación de memoria.
// Esto te dirá la línea exacta que creó el objeto que se fugó.
{$define RawStackTraces}
