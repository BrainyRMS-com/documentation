---
version: "1.7.12"
publishdate: "2025-10-20"
---

# INTRODUCTION

## API goal

The goal of these API XML is to give PMS/CRS the possibility to use PMS main functions inside their software.

These functions are:

1. **Download reservations**: PMS periodically retrieves new or modified reservations from the channels; retrieved reservations are then stored in a local database; API functions let Brainy retrieves these reservations.
2. **Read PMS Inventory**: the local inventory is where it is stored daily room's data (availability, rate etc).
3. **Update PMS Inventory and linked channels**: when the local inventory is updated, updated data are then forwarded to the channels.

---

## Data exchange mechanism

Every call to the API is an HTTP POST to the address:

**TEST ENVIRONMENT**
```
https://apitest.yourwebsite.com/be/search/xml.jsp
```

**PROD ENVIRONMENT**
```
https://api.yourwebsite.com/be/search/xml.jsp
```

The HTTP request headers must contains `ContentType = "text/xml"`.

Every request is added to an internal QUEUE that is composed by a Waiting Queue and an Active Queue.

For every property the Waiting queue accepts up to `N` requests: it means that an external software can send simultaneously up to `N` requests for the same property.

For every property the Active queue accepts up to `M` requests of different type: it means that PMS can simultaneously elaborate, for the same property, up to `M` different requests queued in the Waiting Queue. As a consequence update requests are always elaborated one by one. PMS never processes an update request until the previous one is completed.

Please set your values of `N` and `M` as large as possible.

PMS accepts up to 15.000 availability rows per property every 30 minutes.
This limit can be temporarily changed if needed.

---

## Data types

| Type     | Format              | Description                                                                   |
|----------|---------------------|-------------------------------------------------------------------------------|
| String   |                     | Any alphanumeric value                                                        |
| Integer  |                     | Any integer number either positive or negative in decimal base representation |
| Double   |                     | Any real number either positive or negative in decimal base representation    |
| Boolean  | true / false        |                                                                               |
| Date     | YYYY-MM-DD          |                                                                               |
| DateTime | YYYY-MM-DD hh:mm:ss | TimeZone CET/CEST                                                             |

---

## Request message structure and access credentials

Every call must be enclosed in a "Request" element that contains the access credentials

**Request element**

| Level | Element/attribute | Type   | Mandatory | Description |
|-------|-------------------|--------|-----------|-------------|
| 1     | **Request**       |        |           |             |
|       | @userName         | String | Y         |             |
|       | @password         | String | Y         |             |
|       | @apikey           | String | N         |             |

Username and password for the API usage can be used to access the PMS extranet too.

For security reasons, the access to the XML interface has a second level authorization control: the caller IP address must be in the PMS whitelist or the Request element must contain an authorized API KEY.

The API KEY is also used to identify the system caller, that's why we strongly suggest to adopt this second method.

API KEY and whitelisted IPs must be set in agreement with Brainy.

---

## Response Message structure

Every response is enclosed in a Response element.

**Response element**

| Level | Element/attribute   | Type   | Mandatory | Description                                                                                       |
|-------|---------------------|--------|-----------|---------------------------------------------------------------------------------------------------|
| 1     | **Response**        |        | 1         |                                                                                                   |
| 2     | **subelement**      |        | 0 - n     | Subelements depend on the request type and are specified in the following chapters and paragraphs |


```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
	<hotel id="324" description="Hotel Milano" currency="EUR"/>
	<hotel id="456" description="Hotel Roma" currency="EUR"/>
</Response>
```

---

## Error Message

Error messages are returned as attribute of an error element.

```xml
<error message="Authentication Failed - Wrong Password"/>
```


# Configuration methods

## getHotels

This method return the list of all hotels associated to an username/password. For each listed hotel it provides an ID and a description. ID must be used to identify the hotel in all other messages.

**Request elements**

| Level | Element/attribute | Type | Mandatory | Description |
|-------|-------------------|------|-----------|-------------|
| 1     | **getHotels**     |      | 1         |             |

**Response elements**

| Level | Element/attribute | Type   | Mandatory | Description                        |
|-------|-------------------|--------|-----------|------------------------------------|
| 1     | **hotel**         |        | 0 - n     |                                    |
|       | @id               | String | Y         | Unique identifier of the hotel     |
|       | @description      | String | Y         | hotel name/ description            |
|       | @currency         | String | Y         | Currency selected for the property |

**Ex:**

```xml
<Request userName="MyLogin" password="MyPassword" apikey="MyApikey">
    <getHotels/>
</Request>
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <hotel id="324" description="Hotel Milano" currency="EUR"/>
    <hotel id="456" description="Hotel Roma" currency="EUR"/>
</Response>
```

---

## getRates

It gives the list of rates for a selected hotel. Each element is characterized by two attributes, rateId and description both required.

**Request elements**

| Level | Element/attribute | Type   | Mandatory | Description |
|-------|-------------------|--------|-----------|-------------|
| 1     | **getRates**      |        | 1         |             |
|       | @hotelId          | String | Y         |             |

**Response elements**

| Level | Element/attribute | Type   | Mandatory | Description                       |
|-------|-------------------|--------|-----------|-----------------------------------|
| 1     | **rate**          |        | 0 - n     |                                   |
|       | @rateId           | String | Y         | Unique identifier of the rateplan |
|       | @description      | String | Y         | rateplan name/ description        |

**Ex:**

```xml
<Request userName="MyLogin" password="MyPassword" apikey="MyApikey">
    <getRates hotelId="324"/>
</Request>
```

```xml
<Response>
    <rate rateId="934" description="std" />
    <rate rateId="1452" description="pkg" />
</Response>
```

---

## getRooms

It gives the list of rooms for a selected hotel.

Each room is represented by a room element.

**Request elements**

| Level | Element/attribute | Type   | Mandatory | Description |
|-------|-------------------|--------|-----------|-------------|
| 1     | **getRooms**      |        | 1         |             |
|       | @hotelId          | String | Y         |             |

**Response elements**

| Level | Element/attribute | Type    | Mandatory | Description                                                 |
|-------|-------------------|---------|-----------|-------------------------------------------------------------|
| 1     | **room**          |         | 0 - n     |                                                             |
|       | @id               | String  | Y         | Unique identifier of the roomtype                           |
|       | @quantity         | Integer | Y         | How many rooms of this type are there in the selected hotel |
|       | @description      | String  | Y         | Roomtype name or description                                |
|       | @baseOccupancy    | Integer |           | Roomtype base occupancy                                     |
|       | @parentRoomId     | String  |           | Roomtype parent ID                                          |
|       | @virtual          | Boolean | Y         | Whether this room is virtual or not                         |
| 2     | **rate**          |         | 0 - n     |                                                             |
|       | @rateId           | String  | Y         |                                                             |


**Ex:**

```xml
<Request userName="MyLogin" password="MyPassword" apikey="MyApikey">
    <getRooms hotelId="324"/>
</Request>

<Response>
    <room id="2092" quantity="4" description="Standard double room" baseOccupancy="2">
        <rate rateId="934" />
        <rate rateId="1452" />
    </room>
    <room id="2093" quantity="1" description="Themed double room" parentRoomId="2092">
        <rate rateId="934" />
        <rate rateId="1452" />
    </room>
    <room id="3384" virtual="true" description="Overbookings" quantity="1">
        <rate rateId="934" />
    </room>
</Response>
```

---

# Reservations

## Reservations retrieval

The **reservations** function let the client retrieve reservations from the PMS local database.

**Request elements**

| Level | Element/attribute | Type    | Mandatory | Description                                                              |
|-------|-------------------|---------|-----------|--------------------------------------------------------------------------|
| 1     | **reservations**  |         | 1         |                                                                          |
|       | @hotelId          | String  | Y         |                                                                          |
|       | @unconfirmed      | Boolean | N         | if value="true" all the other search criteria attributes are ignored.    |
|       | @useDLM           | Boolean | N         | Search criteria<br>true = last modification date<br>false = checkin date |
|       | @startDate        | Date    | N         |                                                                          |
|       | @endDate          | Date    | N         |                                                                          |

Different combinations of attributes correspond to different search criteria:

**Ex:**

**1. To retrieve all unconfirmed reservations from all portals use:**

- unconfirmed = "true"
- omit useDLM
- omit startDate
- omit endDate

The first time this method is used, all reservations are returned. Instead, all reservations are returned since the last call.

```xml
<Request userName="MyLogin" password="MyPassword" apikey="MyApikey">
    <reservations hotelId="3284" unconfirmed="true" />
</Request>
```

**2. To retrieve all the reservations from all portals, created or modified after the last reservations call use:**

- useDLM = "true"
- omit startDate
- omit endDate

```xml
<Request userName="MyLogin" password="MyPassword" apikey="MyApikey">
    <reservations hotelId="3284" useDLM="true" />
</Request>
```

**3. To retrieve all the reservations created or modified between two dates use:**

- useDLM = "true"
- startDate = "YYYY-MM-DD"
- endDate= "YYYY-MM-DD"

```xml
<Request userName="MyLogin" password="MyPassword" apikey="MyApikey">
    <reservations hotelId="3284" useDLM="true" startDate="2023-08-10" endDate="2023-08-12" />
</Request>
```

**4. To retrieve all the reservations with check-in date between two dates use:**

- useDLM = "false"
- startDate = "YYYY-MM-DD"
- endDate= "YYYY-MM-DD"

```xml
<Request userName="MyLogin" password="MyPassword" apikey="MyApikey">
    <reservations hotelId="3284" useDLM="false" startDate="2023-08-10" endDate="2023-08-12" />
</Request>
```

Returned information are a list on reservation elements.

---

## Reservations Notification Push

The process consists of 2 parts.

The first part is the notification.
The second is the request to PMS generated by Brainy to retrieve the details of the reservation.

**Notification PUSH**

Whenever a reservation is created or modified, PMS puts it in a notification queue.

A process checks the queue every 10 seconds and then notifies Brainy through a HTTP GET call to an endpoint provided by Brainy itself.

The request contains 2 parameters, the `id` and `hotelId` that are passed in the querystring in the following format

```
https://<brainy_push_url>?id=xxxxx&hotelId=yyyyy
```

The `id` parameter is the identification code of the reservation in the PMS.

The `hotelId` parameter is the hotel code in PMS.

**Ex:**

```
HTTP GET https://<brainy_push_url>?id=12345&hotelId=5463
```

Brainy must reply with statusCode 200 to aknowledge the receipt of the notification.
Any other statusCode will mean that the notification is unsuccessful.

In such a case PMS will suspend the sending of further notifications for the selected hotel for a period of 5 minutes.

After this time frame, PMS will try again to send the booking notification.

This mechanism will repeat until Brainy responds with a 200 statusCode. Only at that time the lock on the hotel will be removed.

Generally speaking PMS removes a reservation from the notification queue if:

1. it receives a 200 statusCode
2. Brainy downloads the reservation through any of the calls described in the previous paragraph

**Reservation retrieval**

The second part originates on the PMS side.

When Brainy receives the notification, it must send a "reservation" request to retrieve all the reservation data.

**Request elements**

| Level | Element/attribute | Type   | Mandatory | Description                                                          |
|-------|-------------------|--------|-----------|----------------------------------------------------------------------|
| 1     | **reservation**   |        | 1         |                                                                      |
|       | @hotelId          | String | Y         |                                                                      |
|       | @id               | String | Y         | PMS unique identifier of a reservation notified through the HTTP GET |

**Ex:**

```xml
<Request userName="MyLogin" password="MyPassword" apikey="MyApikey">
    <reservation hotelId="3284" id="3257318" />
</Request>
```

The response contains only one reservation element as described in the following paragraph.

Whenever Brainy retrieves a notified reservation we strongly suggest to send a **reservationConfirm**. This way it can periodically send "reservations" requests with unconfirmed="true" as a fallback mechanism.

---

## Reservations response messages

Reservations response messages contain a list of reservation elements.

The reservation element has a very complex structure and many of the attributes and subelements are not mandatory but portal-dependent.

**Reservation element structure**

| Level | Element/attribute           | Type     | Mandatory | Description                                                                                                                           |
|-------|-----------------------------|----------|-----------|---------------------------------------------------------------------------------------------------------------------------------------|
| 1     | **reservation**             |          | 0 - n     |                                                                                                                                       |
|       | @id                         | String   | Y         | PMS Reservation unique identifier                                                                                                     |
|       | @portalId                   | String   | Y         | PMS Portal identifier                                                                                                                 |
|       | @status                     | String   | Y         | Reservation status<br>The list of possible values is reported below                                                                   |
|       | @hotelId                    | String   | Y         | PMS Hotel Id                                                                                                                          |
|       | @dlm                        | DateTime | Y         | PMS last retrieval date and time                                                                                                      |
|       | @checkin                    | Date     | Y         | If the resravtion is for multiple roomstays with different checkin date the first one is taken                                        |
|       | @checkout                   | Date     | Y         | If the resravtion is for multiple roomstays with different checkout date the last one is taken                                        |
|       | @creation_date              | DateTime | Y         | Creation date and time                                                                                                                |
|       | @cancellation_date          | DateTime | N         | Cancellation date and time                                                                                                            |
|       | @firstName                  | String   | N         | The first name of the customer that has completed this reservation                                                                    |
|       | @lastName                   | String   | N         | The last name of the customer that has completed this reservation                                                                     |
|       | @address                    | String   | N         | Customer address                                                                                                                      |
|       | @city                       | String   | N         | Customer city                                                                                                                         |
|       | @zipCode                    | String   | N         | Customer Zip Code                                                                                                                     |
|       | @country                    | String   | N         | ISO Alpha-2 country code                                                                                                              |
|       | @lang                       | String   | N         | Language used by the customer or set as preferred language during the booking                                                         |
|       | @rooms                      | Integer  | N         | Total number of booked rooms                                                                                                          |
|       | @persons                    | Integer  | N         | Total number of hosted adults                                                                                                         |
|       | @children                   | Integer  | N         | Total number of hosted children                                                                                                       |
|       | @price                      | Double   | N         | Total reservation amount                                                                                                              |
|       | @commission                 | Double   | N         | Reservation commission amount                                                                                                         |
|       | @currencycode               | String   | N         | ISO 4217 Currency Code                                                                                                                |
|       | @paymentType                | String   | N         | The list of available payment types is reported below                                                                                 |
|       | @shop                       | Integer  | N         | Identifies the booking source when the booking is made through the PMS BookingEngine<br>The list of possible values is reported below |
|       | @source_of_business         | String   | N         | Source of business. It can be a Tour Operator, a Travel Agent or a Partenr WebSite of the channel                                     |
| 2     | **Company**                 |          | 0 - 1     | Information's about the Company that made the reservation                                                                             |
|       | CompanyId                   | String   | N         | Company Identifier in the Channel Environment                                                                                         |
|       | CompanyVat                  | String   | N         | VAT Number                                                                                                                            |
|       | CompanyName                 | String   | Y         | Company Name                                                                                                                          |
|       | CompanyAddress              | String   | N         | Address                                                                                                                               |
|       | CompanyCity                 | String   | N         | City                                                                                                                                  |
|       | CompanyCountry              | String   | N         | Country                                                                                                                               |
|       | CompanyPostalcode           | String   | N         | Postal code                                                                                                                           |
| 2     | **room**                    |          | 0 - n     | Contains details for every room stay                                                                                                  |
|       | @id                         | String   | Y         | PMS room type ID                                                                                                                      |
|       | @quantity                   | Integer  | Y         | Number of reserved rooms for the current room stay                                                                                    |
|       | @description                | String   | Y         | Room name                                                                                                                             |
|       | @portalRoomDescription      | String   | N         | Name of the room on the channel                                                                                                       |
|       | @checkin                    | Date     | N         | Check-in date for this room stay, can be different from the reservation checkin                                                       |
|       | @checkout                   | Date     | N         | The check-out date for this room, can be different from the reservation checkout                                                      |
|       | @rateId                     | String   | N         | PMS rate plan code applied to this room stay                                                                                          |
|       | @rateDescription            | String   | N         | Rate plan description                                                                                                                 |
|       | @portalRateDescription      | String   | N         | Channel rate plan description                                                                                                         |
|       | @currency                   | String   | N         | ISO 4217 Currency Code                                                                                                                |
|       | @price                      | Double   | N         | Room stay total base amount (don not include discounts and supplements)                                                               |
|       | @totalPrice                 | Double   | N         | Room stay total amount (total base amount +supplements-offers)                                                                        |
|       | @adults                     | Integer  | N         | Number of adults in this room stay                                                                                                    |
|       | @children                   | Integer  | N         | Number of children in this room stay                                                                                                  |
|       | @commission                 | Double   | N         | Commission amount applied by the channel for the current room stay                                                                    |
|       | @status                     | String   | Y         | Room status (book, modified, cancelled etc)<br>The list of possible values is reported below                                          |
| 3     | **childAge**                | String   | 0 - n     | It's a subelement of room element and it is used to report the age the children                                                       |
|       | @age                        | Integer  | Y         | Age of the nth child in the room stay                                                                                                 |
| 3     | **dayPrice**                |          | 0 - n     | Subelement used to specify the room stay daily base amount                                                                            |
|       | @day                        | Date     | Y         |                                                                                                                                       |
|       | @price                      | Double   | Y         | Daily total base amount                                                                                                               |
|       | @roomId                     | String   | N         | Always the same value as in the father room stay<br>Maintained only for back compatibility                                            |
|       | @rateId                     | String   | N         | When the channel uses the mixed rates model, the rate plan ID can be different respect to the father room stay rateId                 |
| 3     | **supplement**              |          | 0 - n     | Supplements or fees infos                                                                                                             |
|       | @description                | String   | Y         |                                                                                                                                       |
|       | @supplementId               | String   | N         | Supplement identifier (should be ENUMed by PMS)                                                                                       |
|       | @price                      | Double   | Y         | Total amount                                                                                                                          |
|       | @number                     | Integer  | Y         | Quantity of this service bought by the client (=0 if it cannot be quantified)                                                         |
|       | @type                       | Integer  | Y         | 0=daily, 1=per person, 2=by number, 3=per person per night, 4=by number per night                                                     |
| 3     | **guest**                   |          | 0 - n     |                                                                                                                                       |
|       | @firstName                  | String   | Y         |                                                                                                                                       |
|       | @secondName                 | String   | Y         |                                                                                                                                       |
|       | @country                    | String   | N         | ISO Alpha-2 country code                                                                                                              |
| 2     | **tax**                     |          | 0 – n     | When one or more tax elements are present the reservation amount is the sum of the room prices + the tax amounts                      |
|       | @amount                     | Double   | Y         | Tax amount                                                                                                                            |
|       | @description                | String   | Y         | Tax description                                                                                                                       |

---

**Reservation and Room Status table**

| Code | Description                   |
|------|-------------------------------|
| 2    | SUBMITTED (not yet confirmed) |
| 4    | CONFIRMED                     |
| 5    | REJECTED                      |
| 6    | NO SHOW                       |
| 7    | DELETED/CANCELLED             |
| 8    | MODIFIED                      |

---

**Payment type List**

| Code | Description            |
|------|------------------------|
| 1    | transfer               |
| 2    | postal_order           |
| 3    | paypal                 |
| 4    | credit_card            |
| 5    | cash                   |
| 6    | mercadopago            |
| 7    | stripe                 |
| 8    | etrans                 |
| 9    | mobipaid               |
| 10   | payway                 |
| 11   | redsys                 |
| 12   | satispay               |
| 13   | payu                   |
| 14   | payulatam              |
| 15   | clicpay                |
| 16   | realex                 |
| 17   | paycomet               |
| 18   | payzen                 |
| 20   | comerciaglobalpayments |
| 21   | ogone                  |
| 22   | Voucher                |
| 23   | nexi                   |
| 24   | sogecommerce           |
| 27   | bizum                  |
| 28   | epayco                 |
| 29   | syspay                 |
| 30   | cecabank               |
| 31   | bccpayway              |
| 32   | K&H PG                 |

---

**Shop List**

| Code | Description             |
|------|-------------------------|
| 1    | PMS Booking Engine      |
| 3    | Facebook                |
| 4    | Tripadvisor             |
| 5    | Google                  |
| 8    | MyHotelShop             |
| 11   | Trivago Fastconnect     |
| 12   | Le bon Coin (Pilgo)     |
| 14   | Small Hotels Argentina  |
| 15   | Trivago Express Booking |
| 16   | Calafate Travel         |
| 18   | PMS CRS                 |
| 20   | Google FBL              |
| 21   | Trivago CPA             |

---

**REMARK:** PMS tries to decode the room present in a reservation retrieved from a channel, with one of those defined in PMS (room mapping). 
If it occurs, as usual, the roomId returned in the reservation message is the PMS room identification code (i.e. one of those you retrieve with the getRooms message).

---

**Reservation example**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
<reservation id="91138035" hotelId="4086" portalId="63" checkin="2023-10-03" checkout="2023-10-05" firstName="Giulio" lastName="Cesare" rooms="2" adults="6" children="1" persons="7" city="Roma" country="IT" lang="en" address="Fori Imperiali" zipCode="00187" price="508.0" commission="0.0" status="4" currencycode="EUR" paymentType="4" offer="" creation_date="2023-08-17 09:41:33" dlm="2023-08-17 09:41:33" source_of_business="">
    <Company CompanyId="4087" CompanyVat="01234567890" CompanyName="ACME Inc." CompanyAddress="Milano" CompanyCountry="IT" CompanyPostalcode="20137"/>
    <room id="41699" description="Family" portalRoomDescription="Family" checkin="2023-10-03" checkout="2023-10-05" rateId="26505" rateDescription="" portalRateDescription="BB NR - Breakfast included" quantity="1" currency="EUR" price="240.0" totalPrice="236.0" adults="4" children="0" commission="0.0" status="4">
        <supplement supplementId="7271" description="parking" price="20.0" type="0" number="1" />
        <offer offerId="23911" description="Corporate Offer" amount_after_tax="-24.0"/>
    	<dayPrice day="2023-10-03" roomId="41699" price="120.0"/>
    	<dayPrice day="2023-10-04" roomId="41699" price="120.0"/>
    </room>
    <room id="20022" description="Classic DBL" portalRoomDescription="Classic DBL" checkin="2023-10-03" checkout="2023-10-05" rateId="13086" rateDescription="" portalRateDescription="BB - Breakfast included" quantity="1" currency="EUR" price="280.0" totalPrice="272.0" adults="2" children="1" commission="0.0" status="4">
        <supplement supplementId="7271" description="parking" price="20.0" type="0" number="1" />
        <offer offerId="23911" description="Corporate Offer" amount_after_tax="-28.0"/>
		<childAge age="3"/>
        <dayPrice day="2023-10-03" roomId="20022" price="140.0"/>
        <dayPrice day="2023-10-04" roomId="20022" price="140.0"/>
        <guest firstName="Cleopatra" secondName="Regina" />
    </room>
</reservation>
</Response>
```

---

## Reservation Confirm

This function allows PMS to have the confirmation from Brainy that the reservation has been downloaded. Without this, the reservation will be returned as unconfirmed in reservation request.

**Request elements**

| Level | Element/attribute      | Type   | Mandatory | Description                   |
|-------|------------------------|--------|-----------|-------------------------------|
| 1     | **reservationConfirm** |        |           |                               |
|       | @hotelId               | String | Y         |                               |
|       | @id                    | String | Y         | PMS reservation internal code |
|       | @confirmationId        | String | Y         | Brainy confirmation ID        |

**Ex:**

```xml
<Request userName="MyLogin" password="MyPassword" apikey="MyApikey">
    <reservationConfirm hotelId="5854" id="62395874" confirmationId="1234"/>
</Request>

<Response>
    <ok/>
</Response>
```

From now on the reservation with id="62395874" will not be returned unless you click on the "ON/OFF" button

---


# Read and Update Inventory

## The PMS Inventory

The PMS Inventory is a calendar of room availabilities and rates stored on the local PMS database.

For each room type and each day it is possible to define rate-based prices.

Every time the calendar of a room type and linked rate types are updated, the mapped "room types / rate plans" calendars on the channels are updated as well.

Brainy XML API provides two methods to respectively read and update inventory data. These two method are:

1. **view** : get inventory data
2. **modify** : update inventory data

Structure and the usage of these two so important methods are showed in the next paragraphs.

---

## Business Rules

Hotels can define one or more business rules to set up Derived Products (Room Rules) or rules to recalculate the data to send to a portal room and rate (Portals Rule).

With a Room Rule it is possible to link a room/rate to another room/rate, i.e. it is possible to calculate the availability, and/or the rate and/or the min stay of a room/rate combination starting from a "linked" room/rate combination.

Through a set of Room Rules it is possible to derivate all room/rates combinations from a base room/rate.

By default the ratio between the PMS inventory and the mapped rooms/rates channels is 1 to 1.

For instance, if we put in the PMS inventory 100,00€ on the Single Room and Standared Rate, 100,00€ will be then sent to booking.com for the Double - Standard Rate Plan, to Expedia for the Standard room - Standard rate Plan and so on.

---

## Availability element

Availability element represents the basic block of information for a defined room on a defined day. The Inventory is a collection of availability objects.

| Level | Element/attribute   | Type    | Mandatory | Description                                                                                                                                                     |
|-------|---------------------|---------|-----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | **availability**    |         |           |                                                                                                                                                                 |
|       | @roomId             | String  | Y         | Room type ID                                                                                                                                                    |
|       | @day                | Date    | Y         |                                                                                                                                                                 |
|       | @quantity           | Integer | N         | Number of available rooms                                                                                                                                       |
| 2     | **rate**            |         |           |                                                                                                                                                                 |
|       | @rateId             | String  | Y         | Rate plan ID                                                                                                                                                    |
|       | @price              | Double  | N         |                                                                                                                                                                 |
|       | @minimumStay        | Integer | N         |                                                                                                                                                                 |
|       | @maximumStay        | Integer | N         |                                                                                                                                                                 |

---

## View Request

View request is used to retrieve the inventory of a property in a calendar interval between two dates.

**Request elements**

| Level | Element/attribute | Type   | Mandatory | Description |
|-------|-------------------|--------|-----------|-------------|
| 1     | **view**          |        | 1         |             |
|       | @hotelId          | String | Y         |             |
|       | @startDate        | Date   | Y         |             |
|       | @endDate          | Date   | Y         |             |

The response to a view call is a list of availability elements

**Ex:**

```xml
<Request userName="MyLogin" password="MyPassword">
    <view hotelId="1111" startDate="2024-10-12" endDate="2024-10-12" />
</Request>

<Response>
    <availability day="2024-10-12" roomId="2091" quantity="5" >
        <rate rateId="7420" price="80.0" minimumStay="1" maximumStay="100" />
        <rate rateId="7420" price="70.0" minimumStay="1" maximumStay="7" />
    </availability>
</Response>
```

---

## Modify Request

Modify request is used to send updates to the inventory of a property in a calendar interval between two dates.

**Request elements**

| Level | Element/attribute | Type    | Mandatory | Description                                                                                                                                                                                                                                                             |
|-------|-------------------|---------|-----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | **modify**        |         | 1         |                                                                                                                                                                                                                                                                         |
|       | @hotelId          | String  | Y         |                                                                                                                                                                                                                                                                         |
|       | @startDate        | Date    | Y         |                                                                                                                                                                                                                                                                         |
|       | @endDate          | Date    | Y         |                                                                                                                                                                                                                                                                         |
| 2     | **availability**  |         | 1 - n     | Array of Availability elements (see above paragraph)<br>The attribute day of any availability element must be between the startDate and endDate specified in the modify element<br>A request cannot contain more than one availability element with same roomId and day |

**Ex:**

```xml
<Request userName="MyLogin" password="MyPassword">
    <modify hotelId="1111" startDate="2024-10-12" endDate="2024-10-14" >
        <availability day="2024-10-12" roomId="1" quantity="5">
            <rate rateId="2782" price="50.0" minimumStay="1" />
            <rate rateId="7421" price="70.0" minimumStay="1" />
        </availability>
        <availability day="2024-10-14" roomId="1">
            <rate rateId="7421" price="70.0" />
        </availability>
    </modify>
</Request>
```

A modify message cannot contain more than one availability element having same roomId and same day.

The availability subelements are optional.

An availability element cannot contain more than one rate sub element having same rateId.

The result of a **Modify** call can be:

a) **completely wrong**: an error has occurred during the Inventory update procedure; no data has been saved and forwarded to any channel.

b) **partially successful**: Inventory has been successfully updated, but an error has occurred while sending data to one or more channel.

c) **completely successful**: Inventory and channels have been successfully updated.

In the first and second case an error element will be returned as child of the Response element.

**Ex a):**

```xml
<Response>
    <error message="Problem have been encountered in the modification of the inventory"/>
</Response>
```

In this case the error element contains the list of portals with update errors.

**Ex b):**

```xml
<Response>
    <error message="Problem on portals update">
        <portal id="124" message="Login Failed" code="2101">
        </portal>
        <portal id="3" message="error on update of room single" code="2301">
        </portal>
        ...
    </error>
</Response>
```

**Ex c):**

```xml
<Response>
    <ok/>
</Response>
```

When the request contains one or more wrong roomId and or rateId, PMS discards the corresponding elements and it raises a warning message

```xml
<Response>
    <ok/>
    <warnings>
        <warning message="roomId 58234 not found for hotelId 4018" />
    </warnings>
</Response>
```

---

**REMARKS**

**Update process speed**

When you send a modify request, PMS updates the inventory and immediately forwards data to the channels. The process can take up to 10 minutes or more, depending on several factor like how many channels the hotel is connected to, the number of rooms to update etc.

---


# Portal Error Handling

## Error codes

Error codes are 4 digits integer.

The error codes starting with 1 are referred to PMS subsystem errors

| Code | Description                | Explanation                                                                                                                                                          |
|------|----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1000 | Generic error              | Unclassified error.                                                                                                                                                  |
| 1001 | Internal Timeout Error     | These are internal system error at channel level. Brainy can try to resend the message again in a few minutes.<br>An incremental retry strategy can be put in place. |
| 1002 | Internal Error             |                                                                                                                                                                      |
| 1003 | Internal Server Error      |                                                                                                                                                                      |
| 1004 | Database error             |                                                                                                                                                                      |
| 1010 | Malformed XML              | The message sent by Brainy to PMS is not compliant with the PMS specifications.                                                                                      |
| 1011 | Invalid API error          |                                                                                                                                                                      |
| 1012 | Configuration Error        | This error happens whenever one of the mapping codes used in the message (room type id, rate plan id, etc) does not belong to the hotel.                             |
| 1100 | Auth denied                | These are authorization errors. Brainy should avoid to retry to send the message as is since an operator action is required to remove the cause of the error.        |
| 1101 | Wrong Credentials          |                                                                                                                                                                      |
| 1103 | Insufficient access rights |                                                                                                                                                                      |
| 1110 | Too Many requests          | Hotel has been temporarily blocked since PMS has received too many request in the last hour. Hotel is automatically unblocked every hour.                            |
| 1111 | Blocked account            | Hotel has been blocked. To unblock it Brainy should contact PMS support team.                                                                                        |

The error codes starting with 2 are referred to channel subsystem errors.

| Code | Description                | Explanation                                                                                                                                                                                                                                                                                                        |
|------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2001 | Internal Error             | These are internal system error at channel level. Brainy can try ro resend the message again in a few minutes.<br>An incremental retry strategy can be put in place.                                                                                                                                               |
| 2003 | Internal Server Error      |                                                                                                                                                                                                                                                                                                                    |
| 2002 | Internal Timeout Error     |                                                                                                                                                                                                                                                                                                                    |
| 2004 | Database error             |                                                                                                                                                                                                                                                                                                                    |
| 2010 | Malformed XML              | The message sent by PMS to the channel is not compliant with the channel specifications.<br>The PMS team must operate to solve the related issue.                                                                                                                                                                  |
| 2011 | Invalid API Error          |                                                                                                                                                                                                                                                                                                                    |
| 2100 | Auth denied                | These are authorization errors. Brainy should avoid to retry to send the message as is since an operator action is required to remove the cause of the error.                                                                                                                                                      |
| 2101 | Wrong Credentials          |                                                                                                                                                                                                                                                                                                                    |
| 2103 | Insufficient access rights |                                                                                                                                                                                                                                                                                                                    |
| 2202 | Hotel not found            | This error happens whenever one of the mapping codes used in the message (room type id, rate plan id, etc) does not belong to the account.<br>An operator action is required to remove the cause of the error Message example: You either specified an invalid hotelID or your account is not linked to this hotel |
| 2203 | Mapping Error              |                                                                                                                                                                                                                                                                                                                    |
| 2300 | Allotment restrictions     | It means that there is a close out request for one or more room type with a base allotment.                                                                                                                                                                                                                        |
| 2301 | Rate restrictions          | It happens when there exist some business restrictions like for instance:<br>• lower or upper threshold for rates<br>• upper threshold for minimum stay                                                                                                                                                            |
| 2302 | Min Stay Restrictions      |                                                                                                                                                                                                                                                                                                                    |
| 2303 | Availability restrictions  |                                                                                                                                                                                                                                                                                                                    |
| 2304 | Business restrictions      |                                                                                                                                                                                                                                                                                                                    |

---

#  Contacts

## Brainy

info@brainy-rms.com

## PMS

your_help_account@yourwebsite.com
+39 000 000 0000

---
