*&---------------------------------------------------------------------*
*& Report Z_FILL_DYNAMIC_STRUCTURE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_fill_dynamic_structure.

select from bseg
  FIELDS BUKRS,
BELNR,
GJAHR,
max( GSBER ) AS gsber,
sum( DMBTR ) as dmbtr,
sum( WRBTR ) as wrbtr
  WHERE GJAHR = 2021
  GROUP BY
    BUKRS, BELNR, GJAHR
  into table @DATA(documents).


TYPES: BEGIN OF values_ty,
         rowtxt TYPE char40,
         val1   TYPE num13,
         val2   TYPE num13,
         val3   TYPE num13,
         val4   TYPE num13,
         val5   TYPE num13,
       END OF values_ty,
       rows_ty TYPE TABLE OF i WITH EMPTY KEY.

DATA values TYPE values_ty.
DATA rows TYPE rows_ty.

rows = VALUE #( ( 1 )
                ( 2 )
                ( 3 )
                ( 4 )
                ( 5 ) ).

*LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).
*  CASE sy-tabix.
*  	WHEN 1.
*      values-val1 = <row>.
*  	WHEN 2.
*      values-val2 = <row>.
*  	WHEN OTHERS.
*  ENDCASE.
*ENDLOOP.

LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).
  ASSIGN COMPONENT ( sy-tabix + 1 ) OF STRUCTURE values TO FIELD-SYMBOL(<value>).
  CHECK <value> IS ASSIGNED.
  <value> = <row>.
ENDLOOP.

WRITE values.
