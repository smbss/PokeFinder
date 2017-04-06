//
//  PkmnSelectorController.swift
//  PokeFinder
//
//  Created by smbss on 06/04/2017.
//  Copyright © 2017 smbss. All rights reserved.
//

import UIKit
import AVFoundation

class PkmnSelectorController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    
    @IBOutlet weak var collection: UICollectionView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var pokemon = [Pokemon]()
    var filteredPokemon = [Pokemon]()
    var inSearchMode = false
    var selectedPkmn: Pokemon?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collection.dataSource = self
        collection.delegate = self
        searchBar.delegate = self
        
            // Changing the search bar button to done
        searchBar.returnKeyType = UIReturnKeyType.done
        
        fetchPokemon()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let mapView = presentingViewController as? ViewController {
            guard selectedPkmn == nil else {
                mapView.selectedPkmn = self.selectedPkmn
                return
            }
        }
    }
    
    func fetchPokemon() {
        for i in 1...251 {
            let pkmn = Pokemon(pokedexId: i)
            pokemon.append(pkmn)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil || searchBar.text == "" {
                // If the text is nil or has been erased we return to the initial collection view
            inSearchMode = false
            collection.reloadData()
                // Making the keyboard disapear
            view.endEditing(true)
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercased()
                // Creating a filtered pokemon list
                // $0 is a placeolder for each item inside the pokemon array
                // We are checking if pokemon.name contains the lower text written on the search bar
            filteredPokemon = pokemon.filter({$0.name.range(of: lower) != nil})
            collection.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PokeCell", for: indexPath) as? PokeCell {
            let poke: Pokemon!
            if inSearchMode {
                poke = filteredPokemon[indexPath.row]
            } else {
                poke = pokemon[indexPath.row]
            }
            cell.configureCell(poke)
            return cell
        } else {
                // If we can't use a reusable cell we will just create a generic one (it shouldn't happen)
            return UICollectionViewCell()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            // This is what happens when a collection view cell is selected
        
            // Here we also need to consider if we are selecting a filtered pokemon cell or not
        var poke: Pokemon!
        if inSearchMode {
            poke = filteredPokemon[indexPath.row]
        } else {
            poke = pokemon[indexPath.row]
        }
        selectedPkmn = poke
        dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if inSearchMode {
            return filteredPokemon.count
        } else {
            return pokemon.count
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: 90, height: 80)
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}
