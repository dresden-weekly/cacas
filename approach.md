# Grobe Übersicht der Vorgehensweise

- minimale Job-Verarbeitung umsetzen
- grobes Zusammentragen der Gesamtheit der zu verwaltenden
  Informationen (Modelle)
- Überlegen was für Events gebraucht werden und in welcher Form sie
  definieren, was für eine Änderung sie repräsentieren
- ein paar *Events*, *Adapter* und den Code, um ihn zu verarbeiten schreiben

# Ein paar Ideen für Details

## Job-Verarbeitung

<!-- Erstmal eine ganz minimalistische Job-Definition (ein YAML-String mit -->
<!-- zwei Keys: 'inventory' und 'playbook') verarbeiten (kleines -->
<!-- Ruby-Skript). Damit sollte eigentlich alles  gehen, was mit Ansible -->
<!-- geht (also *ALLES*). Statt 'inventory' (Inhalt einer Ansible -->
<!-- `inventory`-Datei) vielleicht auch einfach eine 'hosts'-Liste -->
<!-- (ansiblespezifisch mit Elementen wie "trusty64 -->
<!-- ansible_ssh_host=127.0.0.1 ansible_ssh_port=2202"). -->
Besser einfach nur
Als Beispiel einen Redmine Job.


# Weitere Ideen

## Events

Ein *Hash* wie:

    type: Typ
    model: Modell
    fields: Felder


## Event-Verarbeitung

- durch -> *Adapter*


## Adapter

*Adapter* definieren für die einzelnen zu konfigurierenden Einheiten
(Mailserver, Redmine, VM-Pool...), für welche *fields* welcher
*models* sie zuständig sind und welche *Jobs* im einzelnen für welche
*fields* ausgeführt werden sollen:

    models:
      Model_1:
        field_1: [ job_1 ]
        field_2: [ job_1, job_2 ]

Die Job-Templates sind Dateien in entsprechenden Unterverzeichnissen der Adapter:

    job_1/
    ├── create.yml
    ├── delete.yml
    └── update.yml

oder können alternativ zusammen mit den *models* definiert werden:

    models:
      ...
    jobs:
      job_1:
        create:
          ...
        update:
          ...
      ...

Die Hosts (im Regelfall wohl ein einziger) sind entweder im Adapter konfiguriert (Trennung von
Definition und Konfiguration) oder aus den Daten abzuleiten. In jedem
Fall
