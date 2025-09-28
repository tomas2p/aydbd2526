# P2 - Modelo entidad-relación Farmacia
**Fecha:** 24 de septiembre del 2025  
**Autor:** [alu0101474311@ull.edu.es](mailto:alu0101474311@ull.edu.es) (Tomás Pino Pérez)

---

# 1. Diagrama Entidad/Relación Farmacia
```mermaid
flowchart LR
    %% Entidades
    MED[Medicamento]
    LAB[Laboratorio]
    FAM[Familia]
    CLI[Cliente]
    CMP[Compra]
    DET[[DetalleCompra]] 
    
    %% Atributos Medicamento
    MED --- MED_PK((🔑 Código))
    MED --- MED_Nombre((nombre))
    MED --- MED_Tipo((tipo))
    MED --- MED_Stock((stock))
    MED --- MED_Vendidas((vendidas))
    MED --- MED_Precio((precio))
    MED --- MED_Receta((requiere_receta))

    %% Atributos Laboratorio
    LAB --- LAB_PK((🔑 Código))
    LAB --- LAB_Nombre((nombre))
    LAB --- LAB_Telefono((telefono))
    LAB --- LAB_Direccion((direccion))
    LAB --- LAB_Fax((fax))
    LAB --- LAB_Contacto((contacto))

    %% Atributos Familia
    FAM --- FAM_PK((🔑 Código))
    FAM --- FAM_Nombre((nombre))

    %% Atributos Cliente
    CLI --- CLI_PK((🔑 Código))
    CLI --- CLI_Nombre((nombre))
    CLI --- CLI_Direccion((direccion))
    CLI --- CLI_Telefono((telefono))
    CLI --- CLI_Tipo((tipo_cliente))
    CLI --- CLI_Banco(("datos_bancarios (opcional)"))

    %% Atributos Compra
    CMP --- CMP_PK((🔑 Código))
    CMP --- CMP_FechaCompra((fecha_compra))
    CMP --- CMP_FechaPago(("fecha_pago (opcional)"))


    %% Atributos DetalleCompra
    DET --- DET_PK1((🔑 codigo_compra))
	DET --- DET_PK2((🔑 codigo_medicamento))
	DET --- DET_Unidades((unidades))

    %% Conexiones Entidad - Relación (rombos) - Entidad con cardinalidades
    LAB -- "1" --> R1{suministra} -- "N" --> MED
	FAM -- "1" --> R2{clasifica} -- "N" --> MED
	CLI -- "1" --> R3{realiza} -- "N" --> CMP
    CMP -- "1" --> R4{contiene} -- "N" --> DET
    MED -- "1" --> R5{se_vende_en} -- "N" --> DET
    
    %% === Estilos globales para claves primarias (PK) ===
    style MED_PK fill:#3333,stroke-width:2px
    style LAB_PK fill:#3333,stroke-width:2px
    style FAM_PK fill:#3333,stroke-width:2px
    style CLI_PK fill:#3333,stroke-width:2px
    style CMP_PK fill:#3333,stroke-width:2px
    style DET_PK1 fill:#3333,stroke-width:2px
    style DET_PK2 fill:#3333,stroke-width:2px

    %% === Estilos para atributos opcionales ===
    style CLI_Banco stroke-dasharray: 5 5
    style CMP_FechaPago stroke-dasharray: 5 5
```

# 2. Descripción del modelo

## 2.1. Entidades

| Entidad                 |                 Atributos clave                  | Descripción                                                                                                                                               |
| ----------------------- |:------------------------------------------------:| --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Medicamento (MED)**   |                   Código (PK)                    | Identificador único. Otros: nombre, tipo, stock $\ge0$, vendidas $\ge0$, precio $\gt0$, requiere_receta (boolean). FK: codigo_laboratorio, codigo_familia |
| **Laboratorio (LAB)**   |                   Código (PK)                    | Nombre, teléfono, dirección, fax, contacto. Suministra $1:N$ medicamentos                                                                                 |
| **Familia (FAM)**       |                   Código (PK)                    | Nombre. Clasifica $1:N$ medicamentos                                                                                                                      |
| **Cliente (CLI)**       |                   Código (PK)                    | Nombre, dirección, teléfono, tipo_cliente $\in$ {contado, crédito}, datos_bancarios (opcional, solo crédito)                                              |
| **Compra (CMP)**        |                   Código (PK)                    | Fecha_compra $\le$ hoy, fecha_pago (opcional, solo crédito $\ge$ fecha_compra). FK: codigo_cliente                                                        |
| **DetalleCompra (DET)** | PK compuesta: codigo_compra + codigo_medicamento | Unidades $\gt0$. FK: codigo_compra → CMP, codigo_medicamento → MED                                                                                        |

## 2.2. Relaciones

| Relación                    | Cardinalidad | Semántica                                                                                         |
| --------------------------- |:------------:| ------------------------------------------------------------------------------------------------- |
| Laboratorio – Medicamento   |    $1:N$     | Un laboratorio suministra varios medicamentos; cada medicamento tiene un único laboratorio        |
| Familia – Medicamento       |    $1:N$     | Una familia clasifica varios medicamentos; cada medicamento pertenece a una familia               |
| Cliente – Compra            |    $1:N$     | Un cliente puede realizar varias compras; cada compra pertenece a un cliente                      |
| Compra – DetalleCompra      |    $1:N$     | Una compra contiene varios detalles (medicamentos distintos); cada detalle pertenece a una compra |
| Medicamento – DetalleCompra |    $1:N$     | Un medicamento puede aparecer en muchos detalles; cada detalle corresponde a un único medicamento |

## 2.3. Restricciones semánticas

- **Medicamento:**
    - stock, vendidas $\ge0$
    - precio $\gt0$
    - requiere receta: TRUE/FALSE
    - debe tener un laboratorio y una familia asociados
- **Cliente:**
    - tipo_cliente $\in$ {contado, crédito}
    - contado → datos_bancarios = NULL
    - crédito → datos_bancarios obligatorio
- **Compra:**
    - fecha_compra $\le$ hoy
    - fecha_pago nulo si contado
    - fecha_pago $\ge$ fecha_compra si crédito
- **DetalleCompra:**
    - unidades $\gt0$
    - clave compuesta (codigo_compra + codigo_medicamento) → evita repetición del mismo medicamento en la misma compra
    - unidades $\le$ stock disponible del medicamento
- **General:**
    - Una compra debe tener al menos un detalle
    - Cada medicamento en un detalle debe existir en el inventario
