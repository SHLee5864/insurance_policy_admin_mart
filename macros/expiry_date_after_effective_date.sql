{% test expiry_date_after_effective_date(model) %}

select *
from {{ model }}
where expiry_date < effective_date

{% endtest %}
