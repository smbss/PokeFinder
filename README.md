# ![](http://i.imgur.com/MzeQike.png) PokeFinder

This is a location sharing app for [PokemonGo](http://www.pokemongo.com/) players. Users can submit the location of Pokemon that they have seen so that other players can know where to find them. Users can also click on a desired Pokemon and get directions to it on Apple Maps.
This app uses Apple's [CoreLocation](https://developer.apple.com/reference/corelocation) framework to access the user current location and [Alamofire](https://github.com/Alamofire/Alamofire) to retrieve Pokemon data from the [PokeAPI](https://pokeapi.co/docsv1/).  
Pokemon location info that is submitted by users is then saved to a [Firebase Database](https://firebase.google.com/docs/database/) and retrieved using [GeoFire](https://github.com/firebase/geofire) that allows us to make a realtime location query.  
