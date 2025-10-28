**Fecha:** 11 de octubre del 2025

**Autor:** alu0101474311@ull.edu.es (Tomás Pino Pérez)

---

## 1. Diagrama Relacional

```mermaid
erDiagram

    %% === ENTIDADES PRINCIPALES ===
    VIVERO {
        int id_vivero PK
        string nombre
        numeric latitud
        numeric longitud
        string direccion
    }

    ZONA {
        int id_zona PK
        int id_vivero FK
        string nombre
        numeric latitud
        numeric longitud
    }

    PRODUCTO {
        int id_producto PK
        string nombre
        string categoria
        numeric precio
    }

    ZONA_PRODUCTO {
        int id_zona_producto PK
        int id_zona FK
        int id_producto FK
        int cantidad
    }

    EMPLEADO {
        int id_empleado PK
        string nombre
        string apellido
        string cargo
        numeric objetivos_venta
    }

    EMPLEADO_ZONA {
        int id_empleado_zona PK
        int id_empleado FK
        int id_zona FK
        timestamp fecha_inicio
        timestamp fecha_fin
    }

    CLIENTE {
        int id_cliente PK
        string nombre
        string apellido
        string email
    }

    CLIENTE_TAJINASTE_PLUS {
        int id_cliente PK, FK
        smallint mes
        int anio
    }

    PEDIDO {
        int id_pedido PK
        int id_cliente FK
        int id_empleado_gestor FK
        timestamp fecha
        numeric total
    }

    PEDIDO_ITEM {
        int id_pedido_item PK
        int id_pedido FK
        int id_producto FK
        int cantidad
        numeric precio_unitario
    }

    BONIFICACION {
        int id_bonificacion PK
        int id_cliente FK
        smallint mes
        int anio
        numeric monto
    }

    %% === RELACIONES ENTRE TABLAS ===
    VIVERO ||--o{ ZONA : tiene
    ZONA ||--o{ ZONA_PRODUCTO : almacena
    PRODUCTO ||--o{ ZONA_PRODUCTO : pertenece

    EMPLEADO ||--o{ EMPLEADO_ZONA : trabaja_en
    ZONA ||--o{ EMPLEADO_ZONA : asignada_a

    CLIENTE ||--o{ PEDIDO : realiza
    EMPLEADO ||--o{ PEDIDO : gestiona
    PEDIDO ||--o{ PEDIDO_ITEM : contiene
    PRODUCTO ||--o{ PEDIDO_ITEM : vendido_en

    CLIENTE ||--|| CLIENTE_TAJINASTE_PLUS : hereda
    CLIENTE_TAJINASTE_PLUS ||--o{ BONIFICACION : recibe
```
## 2. Script

- **Start-Script:** [run_viveros.sh](./run_viveros.sh)
- **Script:** [p04-modelo-viveros.sql](./p04-modelo-viveros.sql)
- **Salida:** [output](./output.txt)