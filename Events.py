from BeautifulSoup import BeautifulSoup, NavigableString, Tag
import urllib2
import re
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy import *
from datetime import date, datetime
import time

Base = declarative_base()

def strip_for_dict(str):
    pattern = re.compile('[\W_]+')
    return pattern.sub('', str)

class Categories(Base):
    __tablename__ = 'categories'
    category_id = Column(Integer, primary_key=True)
    category_title = Column(String(1024))
    
    def __init__(self, arg1):
        self.category_title = arg1.encode('utf-8')

class Locations(Base):
    __tablename__ = 'locations'
    location_id = Column(Integer, primary_key=True)
    location_title = Column(String(1024))

    def __init__(self, arg1):
        self.location_title = arg1.encode('utf-8')

class Event_Types(Base):
    __tablename__ = 'event_types'
    event_type_id = Column(Integer, primary_key=True)
    event_type_title = Column(String(1024))

    def __init__(self, arg1):
        self.event_type_title = arg1.encode('utf-8')


class EventDetails(Base):
    __tablename__ = 'event_details'
    event_id = Column(Integer, primary_key=True)
    name = Column(String(255))
    start_date = Column(DateTime)
    end_date = Column(DateTime)
    contact_email = Column(String(255))
    contact_name  = Column(String(255))
    contact_number = Column(String(255))
    category = Column(Integer)
    event_type = Column(Integer)
    event_link = Column(String(2084))
    details_link = Column(String(2084))
    location = Column(Integer)
    description = Column(Text)

    def __init__(self, arg1, arg2):
        self.name = arg1.encode('utf-8')
        self.event_link = arg2.encode('utf-8')
        self.start_date = ""
        self.end_date = ""
        self.contact_email = ""
        self.contact_name = ""
        self.contact_number = ""
        self.category = -1
        self.event_type = -1
        self.details_link = ""
        self.location = -1
        self.description = ""

    def display(self):
        print self.name
        print self.event_link
        print self.start_date
        print self.end_date
        print self.contact_email
        print self.contact_name
        print self.contact_number
        print self.category
        print self.event_type
        print self.details_link
        print self.location
        print self.description
        
    def load_details(self):
        pass
                
class OSUEvents(EventDetails):

    def load_details(self, session, categories, locations, event_types):
        html_doc = urllib2.urlopen(self.event_link).read()
        soup = BeautifulSoup(html_doc)

        event_details = soup.table.findAll("tr")
        for d in event_details:
            detail_title = d.findAll("td")[0].contents
            tds = d.findAll("td")[1].contents
            if detail_title[0] == "Event:":
                temp_str = ""
                for c in tds:
                    if len(c) > 0:
                        if isinstance(c,NavigableString)  == False and c.contents:
                            temp_str += str(c.contents[0])
                            continue
                        temp_str += "\n" +str(c)
                self.description = temp_str
                
            if detail_title[0] == "Date and time:" and len(tds) > 0:
                if len(tds) > 1:
                    start_time = re.findall(r'(.*) -', str(tds[2]))
                    end_time = re.findall(r'.* - (.*)', str(tds[2]))
                    if len(start_time) > 0: 
                        t = str(tds[0]) + " " + start_time[0]
                        try: 
                            self.start_date = datetime.strptime(t, "%B %d, %Y %I:%M %p")
                        except:
                            self.start_date = datetime.strptime(str(tds[0]), "%B %d, %Y")
                            
                    else:
                        t = str(tds[0]) + " " + str(tds[2])
                        self.start_date = datetime.strptime(t, "%B %d, %Y %I:%M %p")
                        
                    if len(end_time) > 0:                     
                        t = str(tds[0]) + " " + end_time[0]
                        self.end_date = datetime.strptime(t, "%B %d, %Y %I:%M %p")

                else:
                    self.start_date = datetime.strptime(tds[0], "%B %d, %Y") 
                
            if detail_title[0] == "Location:" and len(tds) == 1:
                stripped_location = strip_for_dict(str(tds[0])) 
                if stripped_location in locations:
                    self.location = locations[stripped_location]#str(tds[0]).encode('utf-8')
                    
                else:
                    new_location = Locations(str(tds[0]).encode('utf-8'))
                    session.add(new_location)
                    session.commit()
                    db_location = session.query(Locations).filter_by(location_title=str(tds[0]).encode('utf-8')).first() 
                    locations[strip_for_dict(db_location.location_title)] = db_location.location_id
                    self.location = locations[stripped_location]
                    
            if detail_title[0] == "Phone Number:" and len(tds) == 1:
                self.contact_number = str(tds[0]).encode('utf-8')
                
            if detail_title[0] == "Event category:" and len(tds) == 1:
                #self.category = str(tds[0]).encode('utf-8')
                stripped_category = strip_for_dict(str(tds[0])) 
                if stripped_category in categories:
                    self.category = categories[stripped_category]#str(tds[0]).encode('utf-8')
                    
                else:
                    new_category = Categories(str(tds[0]).encode('utf-8'))
                    session.add(new_category)
                    session.commit()
                    db_category = session.query(Categories).filter_by(category_title=str(tds[0]).encode('utf-8')).first() 
                    categories[strip_for_dict(db_category.category_title)] = db_category.category_id
                    self.category = categories[stripped_category]
                
            if detail_title[0] == "Event Type:" and len(tds) == 1:
                self.event_type = str(tds[0]).encode('utf-8')    
                stripped_event_type = strip_for_dict(str(tds[0])) 
                if stripped_event_type in event_types:
                    self.event_type = event_types[stripped_event_type]#str(tds[0]).encode('utf-8')
                    
                else:
                    new_event_type = Event_Types(str(tds[0]).encode('utf-8'))
                    session.add(new_event_type)
                    session.commit()
                    db_event_type = session.query(Event_Types).filter_by(event_type_title=str(tds[0]).encode('utf-8')).first() 
                    event_types[strip_for_dict(db_event_type.event_type_title)] = db_event_type.event_type_id
                    self.event_type = event_types[stripped_event_type]            
                
            if detail_title[0] == "Contact:" and len(tds) == 1:
                if isinstance(tds[0],NavigableString)  == False : #tds[0]['href']:
                    self.contact_email = str(tds[0]['href'][7:]).encode('utf-8')
                    self.contact_name = str(tds[0].text).encode('utf-8')
