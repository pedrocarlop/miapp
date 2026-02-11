// swift-tools-version: 5.9
import PackageDescription

/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Package.swift
 - Rol principal: Soporte general de arquitectura: tipos, configuracion o pegamento entre modulos.
 - Flujo simplificado: Entrada: contexto de modulo. | Proceso: ejecutar responsabilidad local del archivo. | Salida: tipo/valor usado por otras piezas.
 - Tipos clave en este archivo: (sin tipos principales declarados en este archivo; puede contener extensiones o constantes)
 - Funciones clave en este archivo: (sin funciones directas visibles; revisa propiedades/constantes/extensiones)
 - Como leerlo sin experiencia:
   1) Busca primero los tipos clave para entender 'quien vive aqui'.
   2) Revisa propiedades (let/var): indican que datos mantiene cada tipo.
   3) Sigue funciones publicas: son la puerta de entrada para otras capas.
   4) Luego mira funciones privadas: implementan detalles internos paso a paso.
   5) Si ves guard/if/switch, son decisiones que controlan el flujo.
 - Recordatorio rapido de sintaxis:
   - let = valor fijo; var = valor que puede cambiar.
   - guard = valida pronto; si falla, sale de la funcion.
   - return = devuelve un resultado y cierra esa funcion.
*/

let package = Package(
    name: "AppModules",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Core", targets: ["Core"]),
        .library(name: "FeatureDailyPuzzle", targets: ["FeatureDailyPuzzle"]),
        .library(name: "FeatureHistory", targets: ["FeatureHistory"]),
        .library(name: "FeatureSettings", targets: ["FeatureSettings"])
    ],
    targets: [
        .target(
            name: "DesignSystem",
            path: "Sources/DesignSystem"
        ),
        .target(
            name: "Core",
            path: "Sources/Core",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "FeatureDailyPuzzle",
            dependencies: ["Core", "DesignSystem"],
            path: "Sources/FeatureDailyPuzzle",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "FeatureHistory",
            dependencies: ["Core", "DesignSystem"],
            path: "Sources/FeatureHistory",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "FeatureSettings",
            dependencies: ["Core", "DesignSystem"],
            path: "Sources/FeatureSettings",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        ),
        .testTarget(
            name: "FeatureDailyPuzzleTests",
            dependencies: ["FeatureDailyPuzzle", "Core"],
            path: "Tests/FeatureDailyPuzzleTests"
        ),
        .testTarget(
            name: "FeatureHistoryTests",
            dependencies: ["FeatureHistory"],
            path: "Tests/FeatureHistoryTests"
        ),
        .testTarget(
            name: "FeatureSettingsTests",
            dependencies: ["FeatureSettings"],
            path: "Tests/FeatureSettingsTests"
        )
    ]
)
