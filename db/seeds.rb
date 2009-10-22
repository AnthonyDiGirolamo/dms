# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

roles = Role.create [
  {:name => 'administrator'},
  {:name => 'employee'},
  {:name => 'manager'},
  {:name => 'corporate'}
]

depts = Department.create [
  {:name => 'Human Resources'},
  {:name => 'Logistics and Supply'},
  {:name => 'IT Support'},
  {:name => 'Sales'},
  {:name => 'Research and Development'}
]

