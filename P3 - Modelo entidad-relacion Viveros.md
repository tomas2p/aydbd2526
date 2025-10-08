**Fecha:** 1 de octubre del 2025

**Autor:** alu0101474311@ull.edu.es (Tomás Pino Pérez)

---

## 1. Diagrama Entidad/Relación

```mermaid
flowchart LR
    %% Entidades
    VIV[Vivero]
    ZON[Zona]
    PRO[Producto]
    EMP[Empleado]
    CLI[Cliente]
	A@{ shape: flip-tri, label: "­" }
	CTP[ClienteTajinastePlus]
    PED[Pedido]
    BON[Bonificacion]

    %% Atributos Vivero
    VIV --- VIV_PK((🔑 id_vivero))
    VIV --- VIV_Nombre((nombre))
    VIV --- VIV_Lat((latitud))
    VIV --- VIV_Lon((longitud))
    VIV --- VIV_Direccion((direccion))

    %% Atributos Zona
    ZON --- ZON_PK((🔑 id_zona))
    ZON --- ZON_Nombre((nombre))
    ZON --- ZON_Lat((latitud))
    ZON --- ZON_Lon((longitud))

    %% Atributos Producto
    PRO --- PRO_PK((🔑 id_producto))
    PRO --- PRO_Nombre((nombre))
    PRO --- PRO_Categoria((categoria))
    PRO --- PRO_Precio((precio))

    %% Atributos Empleado
    EMP --- EMP_PK((🔑 id_empleado))
    EMP --- EMP_Nombre((nombre))
    EMP --- EMP_Apellido((apellido))
    EMP --- EMP_Cargo((cargo))

    %% Atributos Cliente
    CLI --- CLI_PK((🔑 id_cliente))
    CLI --- CLI_Nombre((nombre))
    CLI --- CLI_Apellido((apellido))
    
    %% Atributos ClienteTajinastePlus
    %% CTP --- CTP_Mes((mes))
    %% CTP --- CTP_Año((año))

    %% Atributos Pedido
    PED --- PED_PK((🔑 id_pedido))
    PED --- PED_Fecha((fecha))
    PED --- PED_Total((total))

    %% Atributos Bonificacion
    BON --- BON_PK((🔑 id_bonificacion))
    BON --- BON_Monto((monto))

    %% Relaciones
    VIV -- "1" --> R1{tiene} -- "N" --> ZON
    R2 --- ZON_Cantidad((cantidad))
    ZON -- "1" --> R2{almacena} -- "N" --> PRO
    EMP -- "1" --> R4{trabaja_en} -- "N" --> ZON
    CLI -- "1" --> R6{realiza} -- "N" --> PED
    R7 --- EMP_Ove((objetivos_venta))
    EMP -- "1" --> R7{gestiona} -- "1" --> PED
    R8 --- CTP_Mes((mes))
    R8 --- CTP_Año((año))
    CTP -- "1" --> R8{recibe} -- "N" --> BON
    
    %% Herencia Cliente - ClienteTajinastePlus
    CLI --- A --- CTP

    %% === Estilos globales para claves primarias (PK) ===
    style VIV_PK fill:#3333,stroke-width:4px
    style ZON_PK fill:#3333,stroke-width:4px
    style PRO_PK fill:#3333,stroke-width:4px
    style EMP_PK fill:#3333,stroke-width:4px
    style CLI_PK fill:#3333,stroke-width:4px
    style PED_PK fill:#3333,stroke-width:4px
    style BON_PK fill:#3333,stroke-width:4px
```

## 2. Descripción del modelo

### 2.1. Entidades

| Entidad                  | Atributos clave / PK               | Otros atributos relevantes           |
| ------------------------ | ---------------------------------- | ------------------------------------ |
| **Vivero**               | id_vivero                          | nombre, latitud, longitud, direccion |
| **Zona**                 | id_zona                            | nombre, latitud, longitud            |
| **Producto**             | id_producto                        | nombre, categoria, precio            |
| **Empleado**             | id_empleado                        | nombre, apellido, cargo              |
| **Cliente**              | id_cliente                         | nombre, apellido                     |
| **ClienteTajinastePlus** | id_cliente (hereda de **Cliente**) |                                      |
| **Pedido**               | id_pedido                          | fecha, total                         |
| **Bonificacion**         | id_bonificacion                    | id_cliente (FK), mes, anio, monto    |

### 2.2. Relaciones

| Relación       | Entidades involucradas                          | Cardinalidad / descripción                                                   | Atributos       |
| -------------- | ----------------------------------------------- | ---------------------------------------------------------------------------- | --------------- |
| **tiene**      | Vivero $\rightarrow$ Zona                       | $1:N\rightarrow$ un vivero tiene varias zonas                                |                 |
| **almacena**   | Zona $\rightarrow$ Producto                     | $1:N\rightarrow$ una zona puede almacenar varios productos                   | cantidad        |
| **trabaja_en** | Empleado $\rightarrow$ Zona                     | $1:N\rightarrow$ un empleado puede trabajar en varias zonas                  |                 |
| **gestiona**   | Empleado $\rightarrow$ Pedido                   | $1:1\rightarrow$ un empleado gestiona un pedidos                             | objetivos_venta |
| **realiza**    | Cliente $\rightarrow$ Pedido                    | $1:N\rightarrow$ un cliente puede realizar varios pedidos                    |                 |
| **herencia**   | Cliente $\rightarrow$ ClienteTajinastePlus      | Cliente es padre de ClienteTajinastePlus                                     |                 |
| **recibe**     | ClienteTajinastePlus $\rightarrow$ Bonificacion | $1:N\rightarrow$ un clienteTajinastePlus puede recibir varias bonificaciones | mes, año        |

### 2.3. Restricciones semánticas

- **Empleado**
    - Nunca puede estar asignado a dos zonas simultáneamente.
    - Debe existir un registro histórico por cada asignación temporal (fecha_inicio, fecha_fin).
- **Pedido**
    - Cada pedido tiene **un único responsable** (empleado).
    - Cada pedido pertenece a **un solo cliente**, especialmente si es Tajinaste Plus.
- **Bonificación**
    - Solo aplica a clientes que sean parte del programa **Tajinaste Plus**.
    - La bonificación se calcula por **mes y año**, no puede haber duplicados para el mismo cliente en el mismo período.
- **Georreferenciación**
    - Latitud y longitud de viveros y zonas deben ser válidas según coordenadas geográficas.