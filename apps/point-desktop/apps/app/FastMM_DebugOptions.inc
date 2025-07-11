{*******************************************************}
{      Opciones de Depuraci�n para FastMM               }
{ Para activar una opci�n, quita las llaves { }          }
{ Para desactivarla, pon las llaves de nuevo             }
{*******************************************************}

// -- MODO DE DEPURACI�N COMPLETO --
// Activa la mayor�a de las comprobaciones de seguridad y de fugas.
{$define FullDebugMode}

// -- REPORTE DE FUGAS DE MEMORIA --
// Asegura que se genere el informe de fugas al cerrar.
{$define EnableMemoryLeakReporting}

// -- �LA OPCI�N M�S IMPORTANTE PARA TI! --
// Registra la pila de llamadas en el momento de la asignaci�n de memoria.
// Esto te dir� la l�nea exacta que cre� el objeto que se fug�.
{$define RawStackTraces}
