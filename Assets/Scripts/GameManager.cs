using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using DigitalRuby.LightningBolt;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public GameObject lighteningBoltPrefab;

    public GameObject _target;
    
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        { 
            Debug.Log("Game started");
            
           GameObject temp =  (GameObject)Instantiate(lighteningBoltPrefab, transform.position, transform.rotation);
           LighteningScript script = temp.GetComponent<LighteningScript>();
           script.target = _target;
           script.DoLightening(); 
        }
    }
}
