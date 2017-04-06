//
//  PokeAnnotation.swift
//  PokeFinder
//
//  Created by smbss on 05/10/2016.
//  Copyright © 2016 smbss. All rights reserved.
//

import Foundation

    // Annotations need to inherit from NSObject
class PokeAnnotation: NSObject, MKAnnotation {
    var coordinate = CLLocationCoordinate2D()
    var pokemonNumber: Int
    var pokemonImage: UIImage
    var title: String?
    
    init(coordinate: CLLocationCoordinate2D, pokemon: Pokemon) {
        self.coordinate = coordinate
        self.pokemonNumber = pokemon.pokedexId
        self.pokemonImage = pokemon.image
        self.title = pokemon.name.capitalized
    }
    
}
