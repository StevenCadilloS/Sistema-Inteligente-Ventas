import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';

/// Los modelos son objetos de lectura, pero `desdeFila` es codigo con riesgo:
/// interpreta lo que devuelve PostgREST, y un cast mal puesto ahi tumba la
/// pantalla entera por un dato que en realidad era correcto.
void main() {
  group('soles()', () {
    test('convierte centavos a soles con dos decimales', () {
      expect(soles(250000), 'S/2500.00');
      expect(soles(12345), 'S/123.45');
      expect(soles(5), 'S/0.05');
      expect(soles(0), 'S/0.00');
    });

    test('no arrastra error de punto flotante', () {
      // 2499999 / 100 en double da 24999.989999999998. Si el formato no
      // redondeara bien, el precio saldria con un centavo de menos.
      expect(soles(2499999), 'S/24999.99');
    });
  });

  group('Producto.desdeFila', () {
    Map<String, dynamic> fila({Object? stock = 10, Object? precio = 250000}) => {
      'id_producto': 1,
      'nombre': 'Laptop',
      'descripcion': 'Una laptop',
      'precio_centavos': precio,
      'stock': stock,
      'activo': true,
      'tiene_ofertas': true,
      'id_categoria': 2,
      'categoria': 'Laptops',
      'id_marca': 3,
      'marca': 'Lenovo',
      'imagen': 'laptop.jpg',
    };

    test('lee todos los campos', () {
      final p = Producto.desdeFila(fila());

      expect(p.idProducto, 1);
      expect(p.nombre, 'Laptop');
      expect(p.precioCentavos, 250000);
      expect(p.stock, 10);
      expect(p.tieneOfertas, isTrue);
      expect(p.categoria, 'Laptops');
      expect(p.marca, 'Lenovo');
    });

    test('acepta numeros que vienen como double', () {
      // PostgREST devuelve un bigint o un calculo como num, no como int: un
      // cast directo a int falla y tumba la pantalla por un dato correcto.
      final p = Producto.desdeFila(fila(stock: 10.0, precio: 250000.0));

      expect(p.stock, 10);
      expect(p.precioCentavos, 250000);
    });

    test('los campos opcionales pueden faltar', () {
      final p = Producto.desdeFila({
        'id_producto': 1,
        'nombre': 'Minimo',
        'precio_centavos': 1000,
      });

      expect(p.stock, 0);
      expect(p.activo, isTrue, reason: 'por defecto activo');
      expect(p.tieneOfertas, isFalse);
      expect(p.categoria, isNull);
      expect(p.imagen, isNull);
    });

    test('disponible exige activo y stock', () {
      expect(Producto.desdeFila(fila()).disponible, isTrue);
      expect(Producto.desdeFila(fila(stock: 0)).disponible, isFalse);

      final inactivo = {...fila(), 'activo': false};
      expect(Producto.desdeFila(inactivo).disponible, isFalse);
    });

    test('dos productos con el mismo id son el mismo', () {
      final a = Producto.desdeFila(fila());
      final b = Producto.desdeFila({...fila(), 'nombre': 'Otro nombre'});

      // La igualdad va por id: el feed los reemplaza por id cuando llega una
      // actualizacion de Realtime.
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith cambia solo el stock', () {
      final p = Producto.desdeFila(fila());
      final rebajado = p.copyWith(stock: 3);

      expect(rebajado.stock, 3);
      expect(rebajado.nombre, p.nombre);
      expect(rebajado.precioCentavos, p.precioCentavos);
      expect(rebajado.tieneOfertas, p.tieneOfertas);
    });
  });

  group('EscalonOferta.desdeFila', () {
    test('lee un escalon de descuento', () {
      final e = EscalonOferta.desdeFila({
        'orden': 1,
        'id_oferta': 5,
        'nombre_oferta': 'Descuento 20%',
        'tipo': 'Descuento',
        'porcentaje_descuento': 20,
        'precio_final_centavos': 200000,
      });

      expect(e.orden, 1);
      expect(e.porcentajeDescuento, 20);
      expect(e.esCombo, isFalse);
    });

    test('un combo no trae porcentaje', () {
      final e = EscalonOferta.desdeFila({
        'orden': 1,
        'id_oferta': 4,
        'nombre_oferta': 'Combo Gamer',
        'tipo': 'Combo',
        'porcentaje_descuento': null,
        'precio_final_centavos': 20000,
      });

      expect(e.porcentajeDescuento, isNull);
      expect(e.esCombo, isTrue,
          reason: 'sin porcentaje, el precio final lo fija la oferta');
    });
  });

  group('CompraHistorial.desdeFila', () {
    test('lee una compra con oferta', () {
      final c = CompraHistorial.desdeFila({
        'id_venta': 7,
        'fecha_hora': '2026-09-11T15:30:00Z',
        'producto': 'Laptop',
        'cantidad': 1,
        'nombre_oferta': 'Descuento 20%',
        'total_centavos': 200000,
      });

      expect(c.idVenta, 7);
      expect(c.producto, 'Laptop');
      expect(c.tuvoOferta, isTrue);
      expect(c.totalCentavos, 200000);
    });

    test('sin oferta, tuvoOferta es falso', () {
      final c = CompraHistorial.desdeFila({
        'id_venta': 8,
        'fecha_hora': '2026-09-11T15:30:00Z',
        'producto': 'Mouse',
        'cantidad': 1,
        'nombre_oferta': null,
        'total_centavos': 12000,
      });

      expect(c.tuvoOferta, isFalse);
    });

    test('la fecha se convierte a hora local', () {
      final c = CompraHistorial.desdeFila({
        'id_venta': 9,
        'fecha_hora': '2026-09-11T15:30:00Z',
        'producto': 'Mouse',
        'cantidad': 1,
        'total_centavos': 12000,
      });

      // El servidor guarda en UTC; la pantalla muestra la hora del cliente.
      expect(c.fecha.isUtc, isFalse);
    });
  });
}
