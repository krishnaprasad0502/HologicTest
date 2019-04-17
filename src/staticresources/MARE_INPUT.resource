{
  "job_type": "big_tsp",
  "driving_directions": false,
  "minimal_output": true,
  "traffic_windows": false,
  "vehicles": [
    {
      "vehicle_id": "the vehicle",
      "type": "car",
      "shifts": [
        {
          "shift_id": "yearlong_shift",
          "shift_start": "2018-11-30T14:29:39-05:00",
          "shift_end": "2019-11-30T14:29:39-05:00",
          "start_location_id": "location_0",
          "end_location_id": "location_0"
        }
      ]
    }
  ],
  "orders": [
    {
      "order_id": "00Q5B00000426S1UAI",
      "min_visits": 1,
      "duration": 1,
      "location_id": "00Q5B00000426S1UAI"
    },
    {
      "order_id": "00Q5B00000429GMUAY",
      "min_visits": 1,
      "duration": 1,
      "location_id": "00Q5B00000429GMUAY"
    }
  ],
  "locations": [
    {
      "location_id": "location_0",
      "latitude": 32.7764749,
      "longitude": -79.93105120000001
    },
    {
      "location_id": "00Q5B00000426S1UAI",
      "latitude": 38.353592,
      "longitude": -81.730999
    },
    {
      "location_id": "00Q5B00000429GMUAY",
      "latitude": 38.330438,
      "longitude": -81.615655
    }
  ],
  "items": [],
  "constraints": [
    {
      "constraint_name": "Travel Time Constraint",
      "constraint_type": "Travel_Time",
      "penalty_per_violation": 1,
      "violation_increment": 1
    },
    {
      "constraint_name": "Visit Range Constraint",
      "constraint_type": "Visit_Range",
      "penalty_per_violation": 100000,
      "violation_increment": 1
    }
  ]
}