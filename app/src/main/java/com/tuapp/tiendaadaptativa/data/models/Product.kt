package com.tuapp.tiendaadaptativa.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey

///**
// * MODELO - PRODUCTO
// * Fase: Persistencia (data)
// * Responsabilidad:
// * - Representar un producto del catálogo de la tienda
// * - Contener: nombre, descripción, precio, categoría, imagen, stock
// * - Se usa para mostrar ofertas al usuario
// */
@Entity(tableName = "products")
data class Product(
    // TODO: @PrimaryKey(autoGenerate = true) val id: Int = 0,
    // TODO: val name: String,
    // TODO: val description: String,
    // TODO: val price: Double,
    // TODO: val category: String,        // "tecnologia", "ropa", "hogar", "accesorios"
    // TODO: val imageUrl: String,
    // TODO: val stock: Int
)
