"""
activities.py - minimal activities dataset returned as JSON.
Add or edit activities here. Each activity has:
  - id, title, emotion, type, payload (used by frontend).
"""
from flask import jsonify

def get_activities():
    activities = [
        {"id":"happy-1","title":"Quick 3-question math","emotion":"happy","type":"quiz",
         "payload":{"questions":[{"q":"2+3?","choices":["4","5","6"],"a":1},
                                {"q":"5-2?","choices":["2","3","4"],"a":1},
                                {"q":"1+1?","choices":["1","2","3"],"a":1}]}},
        {"id":"happy-2","title":"Color and Match","emotion":"happy","type":"color"},
        {"id":"confused-1","title":"Watch hint video (30s)","emotion":"confused","type":"video",
         "payload":{"src":""}},
        {"id":"confused-2","title":"Mini Concept Quiz","emotion":"confused","type":"quiz",
         "payload":{"questions":[{"q":"Which is largest?","choices":["1","10","100"],"a":2}]}},
        {"id":"frustrated-1","title":"Breathing break (30s)","emotion":"frustrated","type":"breathing"},
        {"id":"frustrated-2","title":"Easier practice puzzle","emotion":"frustrated","type":"puzzle"}
    ]
    return activities
