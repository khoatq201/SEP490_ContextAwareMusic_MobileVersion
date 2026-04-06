import { Card, Table, type TableProps } from 'antd';
import { createStyles } from 'antd-style';

/**
 * Types
 */
import type { AnyObject } from 'antd/es/_util/type';
import type { ReactNode } from 'react';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type DataTableProps<T extends AnyObject = any> = TableProps<T> & {
  filter?: ReactNode;
};

const useStyle = createStyles(({ css, prefixCls }) => {
  return {
    customTable: css`
      .${prefixCls}-table {
        .${prefixCls}-table-container {
          .${prefixCls}-table-content {
            .${prefixCls}-table-tbody {
              .${prefixCls}-table-expanded-row.${prefixCls}-table-expanded-row-level-1 {
                > .${prefixCls}-table-cell {
                  padding: 0px;
                  > div {
                    padding: 0px 0px 0px 48px !important;
                  }
                }
              }
            }
          }
        }
      }
    `,
  };
});

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const DataTable = <T extends AnyObject = any>({
  pagination,
  className,
  filter,
  ...tableProps
}: DataTableProps<T>) => {
  const { styles } = useStyle();

  const defaultPagination = {
    pageSize: 10,
    showSizeChanger: true,
    showTotal: (total: number) => `Total ${total} items`,
    className: 'mb-0!',
    ...pagination,
  };

  return (
    <>
      {filter && <Card className='rounded-b-none!'>{filter}</Card>}

      <Card
        styles={{
          body: {
            padding: 0,
          },
        }}
        className={filter ? 'rounded-t-none! border-t-0!' : className}
      >
        <Table
          {...tableProps}
          className={styles.customTable}
          styles={{
            pagination: {
              root: {
                paddingInline: 16,
                paddingBottom: 16,
              },
            },
            content: {
              scrollbarWidth: 'thin',
              scrollbarColor: '#eaeaea transparent',
            },
          }}
          pagination={defaultPagination}
        />
      </Card>
    </>
  );
};
