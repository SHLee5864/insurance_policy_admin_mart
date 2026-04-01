{% test end_date_after_start_date(model) %}

select *
from {{ model }}
where end_date < start_date

{% endtest %}
